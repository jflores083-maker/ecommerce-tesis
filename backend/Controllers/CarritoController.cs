using backend.Data;
using backend.Dtos.Carrito;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Text.Json;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize] // requiere estar autenticado
    public class CarritoController : ControllerBase
    {
        private readonly AppDbContext _db;

        public CarritoController(AppDbContext db)
        {
            _db = db;
        }

        // Helper para obtener el Id de usuario del JWT
        private int GetUserId()
        {
            var idStr = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value
                        ?? User.FindFirst("id")?.Value
                        ?? throw new InvalidOperationException("Id de usuario no presente en el token.");
            return int.Parse(idStr);
        }

        // Parseo de talles (JSON almacenado en Producto.Talles)
        private static List<string> ParseTalles(string? jsonTalles)
        {
            if (string.IsNullOrWhiteSpace(jsonTalles)) return new List<string>();
            try
            {
                var list = JsonSerializer.Deserialize<List<string>>(jsonTalles);
                return list?.Where(s => !string.IsNullOrWhiteSpace(s)).ToList() ?? new List<string>();
            }
            catch
            {
                return new List<string>();
            }
        }

        // Mapeo Carrito -> CarritoDto usando TUS DTOs
        private static CarritoDto MapCarritoDto(Carrito carrito)
        {
            var items = carrito.Items.Select(i => new ItemCarritoDto
            {
                Id = i.Id,
                ProductoId = i.ProductoId,
                Titulo = i.Producto.Titulo,
                ImagenPrincipalUrl = i.Producto.Imagenes
                    .OrderBy(ii => ii.Orden)
                    .FirstOrDefault()?.Url,
                Talle = i.Talle,
                Cantidad = i.Cantidad,
                PrecioUnitarioVigente = i.Producto.Precio
            }).ToList();

            return new CarritoDto
            {
                CarritoId = carrito.Id,
                Items = items
            };
        }

        // GET /api/carrito
        [HttpGet]
        public async Task<ActionResult<CarritoDto>> GetMiCarrito()
        {
            var userId = GetUserId();

            var carrito = await _db.Carritos
                .Include(c => c.Items)
                    .ThenInclude(i => i.Producto)
                        .ThenInclude(p => p.Imagenes)
                .FirstOrDefaultAsync(c => c.UsuarioId == userId);

            if (carrito == null)
            {
                // Carrito nuevo: Items ya inicializado como lista vacía, no hace falta recargar
                carrito = new Carrito { UsuarioId = userId };
                _db.Carritos.Add(carrito);
                await _db.SaveChangesAsync();
            }

            return Ok(MapCarritoDto(carrito));
        }

        // POST /api/carrito/items
        [HttpPost("items")]
        public async Task<ActionResult<CarritoDto>> AgregarItem([FromBody] AgregarItemCarritoDto dto)
        {
            if (!ModelState.IsValid) return ValidationProblem(ModelState);

            var userId = GetUserId();

            // Asegurar carrito (1:1)
            var carrito = await _db.Carritos
                .Include(c => c.Items)
                .FirstOrDefaultAsync(c => c.UsuarioId == userId);

            if (carrito == null)
            {
                carrito = new Carrito { UsuarioId = userId };
                _db.Carritos.Add(carrito);
                await _db.SaveChangesAsync();
                _db.Entry(carrito).Collection(c => c.Items).Load();
            }

            // Validar producto
            var producto = await _db.Productos
                .Include(p => p.Imagenes)
                .FirstOrDefaultAsync(p => p.Id == dto.ProductoId && p.Activo);

            if (producto == null || !string.Equals(producto.Estado, "disponible", StringComparison.OrdinalIgnoreCase))
                return BadRequest("Producto no disponible.");

            // Validar talle — si el producto no tiene talles, acepta cualquier valor (ej: "Único")
            var talles = ParseTalles(producto.Talles);
            if (talles.Any() && !talles.Contains(dto.Talle, StringComparer.OrdinalIgnoreCase))
                return BadRequest("Talle inválido para este producto.");
            
            // Validar stock disponible
            var cantidadEnCarrito = carrito.Items
                .Where(i => i.ProductoId == dto.ProductoId)
                .Sum(i => i.Cantidad);

            if (producto.Stock <= 0)
                return BadRequest("El producto está sin stock.");

            if (cantidadEnCarrito + dto.Cantidad > producto.Stock)
                return BadRequest($"Stock insuficiente. Stock disponible: {producto.Stock - cantidadEnCarrito}.");

            // Unificar por (ProductoId + Talle)
            var existente = carrito.Items.FirstOrDefault(i =>
                i.ProductoId == dto.ProductoId &&
                i.Talle.Equals(dto.Talle, StringComparison.OrdinalIgnoreCase));

            if (existente != null)
            {
                existente.Cantidad += dto.Cantidad;
            }
            else
            {
                carrito.Items.Add(new ItemCarrito
                {
                    ProductoId = dto.ProductoId,
                    Cantidad = dto.Cantidad,
                    Talle = dto.Talle,
                    PrecioUnitarioSnapshot = producto.Precio
                });
            }

            carrito.FechaActualizacion = DateTime.UtcNow;

            try
            {
                await _db.SaveChangesAsync();
            }
            catch (DbUpdateException)
            {
                // Carrera por índice único => merge
                await _db.Entry(carrito).Collection(c => c.Items).LoadAsync();
                var retry = carrito.Items.First(i =>
                    i.ProductoId == dto.ProductoId &&
                    i.Talle.Equals(dto.Talle, StringComparison.OrdinalIgnoreCase));
                retry.Cantidad += dto.Cantidad;
                await _db.SaveChangesAsync();
            }

            // Devolver carrito actualizado
            carrito = await _db.Carritos
                .Include(c => c.Items)
                    .ThenInclude(i => i.Producto)
                        .ThenInclude(p => p.Imagenes)
                .FirstAsync(c => c.UsuarioId == userId);

            return Ok(MapCarritoDto(carrito));
        }

        // PUT /api/carrito/items/{itemId}
        [HttpPut("items/{itemId:int}")]
        public async Task<ActionResult<CarritoDto>> ActualizarItem(int itemId, [FromBody] ActualizarItemCarritoDto dto)
        {
            if (!ModelState.IsValid) return ValidationProblem(ModelState);

            var userId = GetUserId();

            var item = await _db.ItemsCarrito
                .Include(i => i.Carrito)
                .Include(i => i.Producto)
                    .ThenInclude(p => p.Imagenes)
                .FirstOrDefaultAsync(i => i.Id == itemId);

            if (item == null || item.Carrito.UsuarioId != userId)
                return NotFound("Item no encontrado.");

            if (dto.Cantidad < 1)
                return BadRequest("La cantidad mínima es 1.");

            item.Cantidad = dto.Cantidad;
            item.Carrito.FechaActualizacion = DateTime.UtcNow;

            await _db.SaveChangesAsync();

            var carrito = await _db.Carritos
                .Include(c => c.Items)
                    .ThenInclude(i => i.Producto)
                        .ThenInclude(p => p.Imagenes)
                .FirstAsync(c => c.UsuarioId == userId);

            return Ok(MapCarritoDto(carrito));
        }

        // DELETE /api/carrito/items/{itemId}
        [HttpDelete("items/{itemId:int}")]
        public async Task<IActionResult> EliminarItem(int itemId)
        {
            var userId = GetUserId();

            var item = await _db.ItemsCarrito
                .Include(i => i.Carrito)
                .FirstOrDefaultAsync(i => i.Id == itemId);

            if (item == null || item.Carrito.UsuarioId != userId)
                return NotFound("Item no encontrado.");

            _db.ItemsCarrito.Remove(item);
            item.Carrito.FechaActualizacion = DateTime.UtcNow;
            await _db.SaveChangesAsync();

            return NoContent();
        }

        // DELETE /api/carrito
        [HttpDelete]
        public async Task<IActionResult> VaciarCarrito()
        {
            var userId = GetUserId();

            var carrito = await _db.Carritos
                .Include(c => c.Items)
                .FirstOrDefaultAsync(c => c.UsuarioId == userId);

            if (carrito == null) return NoContent();

            if (carrito.Items.Any())
            {
                _db.ItemsCarrito.RemoveRange(carrito.Items);
                carrito.FechaActualizacion = DateTime.UtcNow;
                await _db.SaveChangesAsync();
            }

            return NoContent();
        }
    }
}