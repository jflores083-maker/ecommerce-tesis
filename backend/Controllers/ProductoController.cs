using backend.Data;
using backend.Dtos.Productos;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/productos")]
    public class ProductoController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ProductoController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/productos
        [HttpGet]
        [AllowAnonymous]
        public async Task<ActionResult<IEnumerable<ProductoListaDto>>> GetProductos(
            [FromQuery] string? categoria = null,
            [FromQuery] string? estado = null)
        {
            var query = _context.Productos
                .Include(p => p.Vendedor)
                .Where(p => p.Activo)
                .AsQueryable();

            // Filtrar por categoría si se especifica
            if (!string.IsNullOrEmpty(categoria))
            {
                query = query.Where(p => p.Categoria.ToLower() == categoria.ToLower());
            }

            // Filtrar por estado si se especifica
            if (!string.IsNullOrEmpty(estado))
            {
                query = query.Where(p => p.Estado.ToLower() == estado.ToLower());
            }

            var productos = await query
                .OrderByDescending(p => p.FechaPublicacion)
                .Select(p => new ProductoListaDto
                {
                    Id = p.Id,
                    Titulo = p.Titulo,
                    Precio = p.Precio,
                    Categoria = p.Categoria,
                    Estado = p.Estado,
                    Color = p.Color,
                    VendedorNombre = p.Vendedor.Nombre,
                    FechaPublicacion = p.FechaPublicacion
                })
                .ToListAsync();

            return Ok(productos);
        }

        // GET: api/productos/{id}
        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<ActionResult<ProductoResponseDto>> GetProducto(int id)
        {
            var producto = await _context.Productos
                .Include(p => p.Vendedor)
                .FirstOrDefaultAsync(p => p.Id == id && p.Activo);

            if (producto == null)
                return NotFound("Producto no encontrado");

            var response = new ProductoResponseDto
            {
                Id = producto.Id,
                VendedorId = producto.VendedorId,
                Titulo = producto.Titulo,
                Descripcion = producto.Descripcion,
                Precio = producto.Precio,
                Talles = producto.Talles,
                Categoria = producto.Categoria,
                Estado = producto.Estado,
                Color = producto.Color,
                FechaPublicacion = producto.FechaPublicacion,
                Activo = producto.Activo,
                VendedorNombre = $"{producto.Vendedor.Nombre} {producto.Vendedor.Apellido}"
            };

            return Ok(response);
        }

        // POST: api/productos
        [HttpPost]
        [Authorize] // Solo usuarios autenticados pueden crear productos
        public async Task<ActionResult<ProductoResponseDto>> CreateProducto(ProductoCreateDto dto)
        {
            // Obtener el ID del usuario autenticado desde el token JWT
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int vendedorId))
            {
                return Unauthorized("Token inválido");
            }

            // Verificar que el usuario existe
            var vendedor = await _context.Usuarios.FindAsync(vendedorId);
            if (vendedor == null)
                return NotFound("Usuario no encontrado");

            var producto = new Producto
            {
                VendedorId = vendedorId,
                Titulo = dto.Titulo,
                Descripcion = dto.Descripcion,
                Precio = dto.Precio,
                Talles = dto.Talles,
                Categoria = dto.Categoria,
                Color = dto.Color,
                Estado = dto.Estado,
                FechaPublicacion = DateTime.Now,
                Activo = true
            };

            _context.Productos.Add(producto);
            await _context.SaveChangesAsync();

            var response = new ProductoResponseDto
            {
                Id = producto.Id,
                VendedorId = producto.VendedorId,
                Titulo = producto.Titulo,
                Descripcion = producto.Descripcion,
                Precio = producto.Precio,
                Talles = producto.Talles,
                Categoria = producto.Categoria,
                Estado = producto.Estado,
                Color = producto.Color,
                FechaPublicacion = producto.FechaPublicacion,
                Activo = producto.Activo,
                VendedorNombre = $"{vendedor.Nombre} {vendedor.Apellido}"
            };

            return CreatedAtAction(nameof(GetProducto), new { id = producto.Id }, response);
        }

        // PUT: api/productos/{id}
        [HttpPut("{id}")]
        [Authorize]
        public async Task<IActionResult> UpdateProducto(int id, ProductoUpdateDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized("Token inválido");
            }

            var producto = await _context.Productos.FindAsync(id);

            if (producto == null)
                return NotFound("Producto no encontrado");

            // Solo el dueño del producto puede editarlo
            if (producto.VendedorId != userId)
                return Forbid("No tienes permiso para editar este producto");

            // Actualizar solo los campos que se enviaron
            if (!string.IsNullOrEmpty(dto.Titulo))
                producto.Titulo = dto.Titulo;

            if (!string.IsNullOrEmpty(dto.Descripcion))
                producto.Descripcion = dto.Descripcion;

            if (dto.Precio.HasValue)
                producto.Precio = dto.Precio.Value;

            if (!string.IsNullOrEmpty(dto.Talles))
                producto.Talles = dto.Talles;

            if (!string.IsNullOrEmpty(dto.Categoria))
                producto.Categoria = dto.Categoria;

            if (!string.IsNullOrEmpty(dto.Color))
                producto.Color = dto.Color;

            if (!string.IsNullOrEmpty(dto.Estado))
                producto.Estado = dto.Estado;

            if (dto.Activo.HasValue)
                producto.Activo = dto.Activo.Value;

            await _context.SaveChangesAsync();

            return Ok("Producto actualizado correctamente");
        }

        // DELETE: api/productos/{id}
        [HttpDelete("{id}")]
        [Authorize]
        public async Task<IActionResult> DeleteProducto(int id)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized("Token inválido");
            }

            var producto = await _context.Productos.FindAsync(id);

            if (producto == null)
                return NotFound("Producto no encontrado");

            // Solo el dueño puede eliminar
            if (producto.VendedorId != userId)
                return Forbid("No tienes permiso para eliminar este producto");

            // Borrado lógico
            producto.Activo = false;
            await _context.SaveChangesAsync();

            return Ok("Producto eliminado correctamente");
        }

        // GET: api/productos/mis-productos
        [HttpGet("mis-productos")]
        [Authorize]
        public async Task<ActionResult<IEnumerable<ProductoListaDto>>> GetMisProductos()
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            {
                return Unauthorized("Token inválido");
            }

            var productos = await _context.Productos
                .Include(p => p.Vendedor)
                .Where(p => p.VendedorId == userId && p.Activo)
                .OrderByDescending(p => p.FechaPublicacion)
                .Select(p => new ProductoListaDto
                {
                    Id = p.Id,
                    Titulo = p.Titulo,
                    Precio = p.Precio,
                    Categoria = p.Categoria,
                    Estado = p.Estado,
                    Color = p.Color,
                    VendedorNombre = p.Vendedor.Nombre,
                    FechaPublicacion = p.FechaPublicacion
                })
                .ToListAsync();

            return Ok(productos);
        }
    }
}