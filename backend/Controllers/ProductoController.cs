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
        private readonly IWebHostEnvironment _env;

        public ProductoController(AppDbContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
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
                    VendedorId = p.VendedorId,
                    Titulo = p.Titulo,
                    Descripcion = p.Descripcion,
                    Precio = p.Precio,
                    Stock = p.Stock,
                    Talles = p.Talles,
                    Categoria = p.Categoria,
                    Estado = p.Estado,
                    Color = p.Color,
                    Activo = p.Activo,
                    VendedorNombre = p.Vendedor.Nombre,
                    FechaPublicacion = p.FechaPublicacion,
                    ImagenPrincipalUrl = p.Imagenes.OrderBy(i => i.Orden).Select(i => i.Url).FirstOrDefault()
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
                .Include(p => p.Imagenes)
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
                Stock = producto.Stock,
                Talles = producto.Talles,
                Categoria = producto.Categoria,
                Estado = producto.Estado,
                Color = producto.Color,
                FechaPublicacion = producto.FechaPublicacion,
                Activo = producto.Activo,
                VendedorNombre = $"{producto.Vendedor.Nombre} {producto.Vendedor.Apellido}",
                ImagenPrincipalUrl = producto.Imagenes.OrderBy(i => i.Orden).FirstOrDefault()?.Url
            };

            return Ok(response);
        }

        // POST: api/productos
        [HttpPost]
        [Authorize(Roles = "Admin")]
        [Consumes("multipart/form-data")]
        public async Task<ActionResult<ProductoResponseDto>> CreateProducto([FromForm] ProductoCreateDto dto)
        {
            var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int vendedorId))
                return Unauthorized("Token inválido");

            var vendedor = await _context.Usuarios.FindAsync(vendedorId);
            if (vendedor == null)
                return NotFound("Usuario no encontrado");

            var producto = new Producto
            {
                VendedorId = vendedorId,
                Titulo = dto.Titulo,
                Descripcion = dto.Descripcion,
                Precio = dto.Precio,
                Stock = dto.Stock,
                Talles = dto.Talles,
                Categoria = dto.Categoria,
                Color = dto.Color,
                Estado = dto.Estado,
                FechaPublicacion = DateTime.Now,
                Activo = true
            };

            // Guardar imagen si se adjuntó (se agrega al producto antes del SaveChanges
            // para persistir producto + imagen en un solo roundtrip a la BD)
            string? imagenUrl = null;
            if (dto.Imagen != null && dto.Imagen.Length > 0)
            {
                var uploadsDir = Path.Combine(_env.WebRootPath, "uploads", "productos");
                Directory.CreateDirectory(uploadsDir);

                var ext = Path.GetExtension(dto.Imagen.FileName);
                var fileName = $"{Guid.NewGuid()}{ext}";
                var filePath = Path.Combine(uploadsDir, fileName);

                using (var stream = new FileStream(filePath, FileMode.Create))
                    await dto.Imagen.CopyToAsync(stream);

                imagenUrl = $"/uploads/productos/{fileName}";

                producto.Imagenes.Add(new ImagenProducto
                {
                    Url = imagenUrl,
                    Orden = 0,
                    FechaSubida = DateTime.Now
                });
            }

            _context.Productos.Add(producto);
            await _context.SaveChangesAsync();

            var response = new ProductoResponseDto
            {
                Id = producto.Id,
                VendedorId = producto.VendedorId,
                Titulo = producto.Titulo,
                Descripcion = producto.Descripcion,
                Precio = producto.Precio,
                Stock = producto.Stock,
                Talles = producto.Talles,
                Categoria = producto.Categoria,
                Estado = producto.Estado,
                Color = producto.Color,
                FechaPublicacion = producto.FechaPublicacion,
                Activo = producto.Activo,
                VendedorNombre = $"{vendedor.Nombre} {vendedor.Apellido}",
                ImagenPrincipalUrl = imagenUrl
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

            if (dto.Stock.HasValue)
                producto.Stock = dto.Stock.Value;

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

            var dropEntries = await _context.DropProductos
                .Where(dp => dp.ProductoId == id)
                .ToListAsync();
            _context.DropProductos.RemoveRange(dropEntries);

            await _context.SaveChangesAsync();

            return Ok("Producto eliminado correctamente");
        }

        // PATCH: api/productos/ajustar-precios  — ajuste masivo por porcentaje (solo admin)
        [HttpPatch("ajustar-precios")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> AjustarPrecios([FromBody] AjustarPreciosDto dto)
        {
            if (!ModelState.IsValid) return ValidationProblem(ModelState);
            if (!dto.ProductoIds.Any()) return BadRequest("Seleccioná al menos un producto.");

            var productos = await _context.Productos
                .Where(p => dto.ProductoIds.Contains(p.Id) && p.Activo)
                .ToListAsync();

            if (!productos.Any()) return NotFound("No se encontraron productos válidos.");

            var factor = 1 + dto.Porcentaje / 100m;
            foreach (var p in productos)
                p.Precio = Math.Round(p.Precio * factor, 2);

            await _context.SaveChangesAsync();

            return Ok(new { actualizados = productos.Count });
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
                    VendedorId = p.VendedorId,
                    Titulo = p.Titulo,
                    Descripcion = p.Descripcion,
                    Precio = p.Precio,
                    Stock = p.Stock,
                    Talles = p.Talles,
                    Categoria = p.Categoria,
                    Estado = p.Estado,
                    Color = p.Color,
                    Activo = p.Activo,
                    VendedorNombre = p.Vendedor.Nombre,
                    FechaPublicacion = p.FechaPublicacion,
                    ImagenPrincipalUrl = p.Imagenes.OrderBy(i => i.Orden).Select(i => i.Url).FirstOrDefault()
                })
                .ToListAsync();

            return Ok(productos);
        }
    }
}