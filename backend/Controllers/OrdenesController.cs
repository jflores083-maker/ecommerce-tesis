using backend.Data;
using backend.Dtos.Ordenes;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize] // requiere autenticación
    public class OrdenesController : ControllerBase
    {
        private readonly AppDbContext _db;

        public OrdenesController(AppDbContext db)
        {
            _db = db;
        }

        private int GetUserId()
        {
            var idStr = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                        ?? User.FindFirst("id")?.Value
                        ?? throw new InvalidOperationException("Id de usuario no presente en el token.");
            return int.Parse(idStr);
        }

        private static List<string> ParseTalles(string? jsonTalles)
        {
            if (string.IsNullOrWhiteSpace(jsonTalles)) return new List<string>();
            try { return JsonSerializer.Deserialize<List<string>>(jsonTalles) ?? new(); }
            catch { return new List<string>(); }
        }

        private static decimal CalcularEnvio(string cp, decimal subtotal)
        {
            // PMV: envío fijo o gratis sobre umbral
            return subtotal >= 50000m ? 0m : 2500m;
        }

        // POST /api/ordenes  -> Crea orden desde carrito en TRANSACCIÓN
        [HttpPost]
        public async Task<ActionResult<OrdenResumenDto>> Crear([FromBody] CrearOrdenDto dto)
        {
            if (!ModelState.IsValid) return ValidationProblem(ModelState);

            var userId = GetUserId();

            using var tx = await _db.Database.BeginTransactionAsync();
            try
            {
                var carrito = await _db.Carritos
                    .Include(c => c.Items)
                        .ThenInclude(i => i.Producto)
                    .FirstOrDefaultAsync(c => c.UsuarioId == userId);

                if (carrito == null || !carrito.Items.Any())
                    return BadRequest("El carrito está vacío.");

                // Revalidar disponibilidad y talle
                foreach (var item in carrito.Items)
                {
                    var p = item.Producto;
                    if (p == null || !p.Activo || !string.Equals(p.Estado, "disponible", StringComparison.OrdinalIgnoreCase))
                        return BadRequest($"Producto {item.ProductoId} no disponible.");

                    var talles = ParseTalles(p.Talles);
                    if (!talles.Contains(item.Talle, StringComparer.OrdinalIgnoreCase))
                        return BadRequest($"Talle inválido para producto {item.ProductoId}.");
                }

                // Totales
                var subtotal = carrito.Items.Sum(i => i.Cantidad * i.Producto.Precio);
                var costoEnvio = CalcularEnvio(dto.CodigoPostal, subtotal);
                var total = subtotal + costoEnvio;

                var orden = new Orden
                {
                    CompradorId = userId,
                    Estado = "pendiente",
                    Subtotal = subtotal,
                    CostoEnvio = costoEnvio,
                    Total = total,
                    DireccionEnvio = dto.DireccionEnvio,
                    Ciudad = dto.Ciudad,
                    CodigoPostal = dto.CodigoPostal
                };

                _db.Ordenes.Add(orden);
                await _db.SaveChangesAsync();

                // Items con PRECIO CONGELADO
                var itemsOrden = carrito.Items.Select(i => new ItemOrden
                {
                    OrdenId = orden.Id,
                    ProductoId = i.ProductoId,
                    Cantidad = i.Cantidad,
                    Talle = i.Talle,
                    PrecioUnitario = i.Producto.Precio,
                    Subtotal = i.Cantidad * i.Producto.Precio
                }).ToList();

                _db.ItemsOrden.AddRange(itemsOrden);

                // Vaciar carrito
                _db.ItemsCarrito.RemoveRange(carrito.Items);
                carrito.FechaActualizacion = DateTime.UtcNow;

                await _db.SaveChangesAsync();
                await tx.CommitAsync();

                return Ok(new OrdenResumenDto
                {
                    OrdenId = orden.Id,
                    Estado = orden.Estado,
                    Subtotal = orden.Subtotal,
                    CostoEnvio = orden.CostoEnvio,
                    Total = orden.Total,
                    Fecha = orden.FechaCreacion
                });
            }
            catch
            {
                await tx.RollbackAsync();
                throw;
            }
        }

        // GET /api/ordenes  -> historial del comprador
        [HttpGet]
        public async Task<ActionResult<IEnumerable<OrdenResumenDto>>> Historial()
        {
            var userId = GetUserId();

            var ordenes = await _db.Ordenes
                .Where(o => o.CompradorId == userId)
                .OrderByDescending(o => o.FechaCreacion)
                .Select(o => new OrdenResumenDto
                {
                    OrdenId = o.Id,
                    Estado = o.Estado,
                    Subtotal = o.Subtotal,
                    CostoEnvio = o.CostoEnvio,
                    Total = o.Total,
                    Fecha = o.FechaCreacion
                })
                .ToListAsync();

            return Ok(ordenes);
        }

        // GET /api/ordenes/{id}  -> detalle (sólo dueño)
        [HttpGet("{id:int}")]
        public async Task<ActionResult<OrdenDetalleDto>> Detalle(int id)
        {
            var userId = GetUserId();

            var orden = await _db.Ordenes
                .Include(o => o.Items)
                    .ThenInclude(i => i.Producto)
                .FirstOrDefaultAsync(o => o.Id == id);

            if (orden == null || orden.CompradorId != userId)
                return NotFound();

            var dto = new OrdenDetalleDto
            {
                OrdenId = orden.Id,
                Estado = orden.Estado,
                DireccionEnvio = orden.DireccionEnvio,
                Ciudad = orden.Ciudad,
                CodigoPostal = orden.CodigoPostal,
                Subtotal = orden.Subtotal,
                CostoEnvio = orden.CostoEnvio,
                Total = orden.Total,
                Fecha = orden.FechaCreacion,
                Items = orden.Items.Select(i => new ItemOrdenDto
                {
                    ProductoId = i.ProductoId,
                    Titulo = i.Producto.Titulo,
                    Talle = i.Talle,
                    Cantidad = i.Cantidad,
                    PrecioUnitario = i.PrecioUnitario,
                    Subtotal = i.Subtotal
                }).ToList()
            };

            return Ok(dto);
        }

        // GET /api/ordenes/todas  -> todas las órdenes (Admin)
        [HttpGet("todas")]
        [Authorize(Roles = "Admin")]
        public async Task<ActionResult<IEnumerable<OrdenAdminDto>>> TodasLasOrdenes(
            [FromQuery] string? estado = null)
        {
            var query = _db.Ordenes
                .Include(o => o.Comprador)
                .Include(o => o.Items)
                    .ThenInclude(i => i.Producto)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(estado))
                query = query.Where(o => o.Estado == estado.ToLowerInvariant());

            var ordenes = await query
                .OrderByDescending(o => o.FechaCreacion)
                .Select(o => new OrdenAdminDto
                {
                    OrdenId = o.Id,
                    Estado = o.Estado,
                    NumeroSeguimiento = o.NumeroSeguimiento,
                    CompradorId = o.CompradorId,
                    CompradorNombre = o.Comprador.Nombre,
                    CompradorEmail = o.Comprador.Email,
                    DireccionEnvio = o.DireccionEnvio,
                    Ciudad = o.Ciudad,
                    CodigoPostal = o.CodigoPostal,
                    Subtotal = o.Subtotal,
                    CostoEnvio = o.CostoEnvio,
                    Total = o.Total,
                    Fecha = o.FechaCreacion,
                    Items = o.Items.Select(i => new ItemOrdenDto
                    {
                        ProductoId = i.ProductoId,
                        Titulo = i.Producto.Titulo,
                        Talle = i.Talle,
                        Cantidad = i.Cantidad,
                        PrecioUnitario = i.PrecioUnitario,
                        Subtotal = i.Subtotal
                    }).ToList()
                })
                .ToListAsync();

            return Ok(ordenes);
        }

        // PATCH /api/ordenes/{id}/estado  -> enviado/entregado/cancelado (rol vendedor)
        [HttpPatch("{id:int}/estado")]
        [Authorize] // opcional: [Authorize(Roles = "Vendedor")]
        public async Task<IActionResult> ActualizarEstado(int id, [FromBody] ActualizarEstadoOrdenDto dto)
        {
            if (!ModelState.IsValid) return ValidationProblem(ModelState);

            var estado = dto.Estado.Trim().ToLowerInvariant();
            var estadosValidos = new[] { "enviado", "entregado", "cancelado" };
            if (!estadosValidos.Contains(estado))
                return BadRequest("Estado inválido.");

            var orden = await _db.Ordenes.FindAsync(id);
            if (orden == null) return NotFound();

            // (Opcional) Restringir a vendedor dueño de al menos 1 item de esta orden:
            // var vendedorId = GetUserId();
            // var esVendedorDeEstaOrden = await _db.ItemsOrden
            //     .Include(i => i.Producto)
            //     .AnyAsync(i => i.OrdenId == id && i.Producto.VendedorId == vendedorId);
            // if (!esVendedorDeEstaOrden) return Forbid();

            orden.Estado = estado;
            if (!string.IsNullOrWhiteSpace(dto.NumeroSeguimiento))
                orden.NumeroSeguimiento = dto.NumeroSeguimiento;

            orden.FechaActualizacion = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            return NoContent();
        }
    }
}