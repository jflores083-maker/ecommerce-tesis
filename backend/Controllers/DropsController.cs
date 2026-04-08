using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using backend.Data;
using backend.Dtos.Drops;
using backend.Models;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/drops")]
    public class DropsController : ControllerBase
    {
        private readonly AppDbContext _db;
        private readonly IWebHostEnvironment _env;

        public DropsController(AppDbContext db, IWebHostEnvironment env)
        {
            _db = db;
            _env = env;
        }

        // GET /api/drops
        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> GetDrops()
        {
            var drops = await _db.Drops
                .OrderByDescending(d => d.FechaCreacion)
                .Select(d => new
                {
                    d.Id,
                    d.Nombre,
                    d.ImagenUrl,
                    d.FechaCreacion,
                    totalProductos = d.DropProductos.Count
                })
                .ToListAsync();

            return Ok(drops);
        }

        // GET /api/drops/{id}
        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetDrop(int id)
        {
            var drop = await _db.Drops
                .Include(d => d.DropProductos)
                    .ThenInclude(dp => dp.Producto)
                        .ThenInclude(p => p.Imagenes)
                .FirstOrDefaultAsync(d => d.Id == id);

            if (drop == null) return NotFound();

            var dto = new DropResponseDto
            {
                Id = drop.Id,
                Nombre = drop.Nombre,
                ImagenUrl = drop.ImagenUrl,
                FechaCreacion = drop.FechaCreacion,
                Productos = drop.DropProductos.Select(dp => new DropProductoDto
                {
                    Id = dp.Producto.Id,
                    Titulo = dp.Producto.Titulo,
                    Precio = dp.Producto.Precio,
                    Estado = dp.Producto.Estado,
                    ImagenUrl = dp.Producto.Imagenes.FirstOrDefault()?.Url
                }).ToList()
            };

            return Ok(dto);
        }

        // GET /api/drops/por-producto/{productoId}
        [HttpGet("por-producto/{productoId}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetDropsPorProducto(int productoId)
        {
            var dropIds = await _db.DropProductos
                .Where(dp => dp.ProductoId == productoId)
                .Select(dp => dp.DropId)
                .ToListAsync();

            return Ok(dropIds);
        }

        // POST /api/drops
        [HttpPost]
        [Authorize(Roles = "Admin")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> CrearDrop(
            [FromForm] string nombre,
            [FromForm] string? productoIds,
            IFormFile? imagen)
        {
            if (string.IsNullOrWhiteSpace(nombre))
                return BadRequest("El nombre es requerido.");

            var drop = new Drop { Nombre = nombre.Trim() };

            if (imagen != null && imagen.Length > 0)
            {
                var dir = Path.Combine(_env.WebRootPath, "uploads", "drops");
                Directory.CreateDirectory(dir);
                var ext = Path.GetExtension(imagen.FileName);
                var fileName = $"drop_{Guid.NewGuid():N}{ext}";
                var path = Path.Combine(dir, fileName);
                using var stream = new FileStream(path, FileMode.Create);
                await imagen.CopyToAsync(stream);
                drop.ImagenUrl = $"/uploads/drops/{fileName}";
            }

            _db.Drops.Add(drop);
            await _db.SaveChangesAsync();

            if (!string.IsNullOrWhiteSpace(productoIds))
            {
                var ids = productoIds.Split(',')
                    .Select(s => int.TryParse(s.Trim(), out var n) ? n : 0)
                    .Where(n => n > 0).Distinct();

                foreach (var pid in ids)
                    _db.DropProductos.Add(new DropProducto { DropId = drop.Id, ProductoId = pid });

                await _db.SaveChangesAsync();
            }

            return CreatedAtAction(nameof(GetDrop), new { id = drop.Id },
                new { drop.Id, drop.Nombre, drop.ImagenUrl, drop.FechaCreacion });
        }

        // PUT /api/drops/{id}
        [HttpPut("{id}")]
        [Authorize(Roles = "Admin")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> ActualizarDrop(
            int id,
            [FromForm] string nombre,
            [FromForm] string? productoIds,
            IFormFile? imagen)
        {
            var drop = await _db.Drops
                .Include(d => d.DropProductos)
                .FirstOrDefaultAsync(d => d.Id == id);

            if (drop == null) return NotFound();
            if (string.IsNullOrWhiteSpace(nombre))
                return BadRequest("El nombre es requerido.");

            drop.Nombre = nombre.Trim();

            if (imagen != null && imagen.Length > 0)
            {
                if (drop.ImagenUrl != null)
                {
                    var old = Path.Combine(_env.WebRootPath, drop.ImagenUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
                    if (System.IO.File.Exists(old)) System.IO.File.Delete(old);
                }
                var dir = Path.Combine(_env.WebRootPath, "uploads", "drops");
                Directory.CreateDirectory(dir);
                var ext = Path.GetExtension(imagen.FileName);
                var fileName = $"drop_{Guid.NewGuid():N}{ext}";
                var path = Path.Combine(dir, fileName);
                using var stream = new FileStream(path, FileMode.Create);
                await imagen.CopyToAsync(stream);
                drop.ImagenUrl = $"/uploads/drops/{fileName}";
            }

            _db.DropProductos.RemoveRange(drop.DropProductos);

            if (!string.IsNullOrWhiteSpace(productoIds))
            {
                var ids = productoIds.Split(',')
                    .Select(s => int.TryParse(s.Trim(), out var n) ? n : 0)
                    .Where(n => n > 0).Distinct();

                foreach (var pid in ids)
                    _db.DropProductos.Add(new DropProducto { DropId = drop.Id, ProductoId = pid });
            }

            await _db.SaveChangesAsync();
            return Ok(new { drop.Id, drop.Nombre, drop.ImagenUrl, drop.FechaCreacion });
        }

        // GET /api/drops/{id}/productos  — IDs de productos en el drop
        [HttpGet("{id}/productos")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> GetProductosDelDrop(int id)
        {
            var ids = await _db.DropProductos
                .Where(dp => dp.DropId == id)
                .Select(dp => dp.ProductoId)
                .ToListAsync();

            return Ok(ids);
        }

        // POST /api/drops/{id}/productos/{productoId}
        [HttpPost("{id}/productos/{productoId}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> AgregarProducto(int id, int productoId)
        {
            var existe = await _db.DropProductos
                .AnyAsync(dp => dp.DropId == id && dp.ProductoId == productoId);

            if (!existe)
            {
                _db.DropProductos.Add(new DropProducto { DropId = id, ProductoId = productoId });
                await _db.SaveChangesAsync();
            }

            return Ok();
        }

        // DELETE /api/drops/{id}/productos/{productoId}
        [HttpDelete("{id}/productos/{productoId}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> QuitarProducto(int id, int productoId)
        {
            var entry = await _db.DropProductos
                .FirstOrDefaultAsync(dp => dp.DropId == id && dp.ProductoId == productoId);

            if (entry != null)
            {
                _db.DropProductos.Remove(entry);
                await _db.SaveChangesAsync();
            }

            return NoContent();
        }

        // DELETE /api/drops/{id}
        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> EliminarDrop(int id)
        {
            var drop = await _db.Drops.FindAsync(id);
            if (drop == null) return NotFound();

            if (drop.ImagenUrl != null)
            {
                var path = Path.Combine(_env.WebRootPath, drop.ImagenUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
                if (System.IO.File.Exists(path)) System.IO.File.Delete(path);
            }

            _db.Drops.Remove(drop);
            await _db.SaveChangesAsync();
            return NoContent();
        }
    }
}
