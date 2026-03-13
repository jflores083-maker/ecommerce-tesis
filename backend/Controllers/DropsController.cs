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

        // POST /api/drops  (Admin)
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

            // Imagen
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

            // Productos
            if (!string.IsNullOrWhiteSpace(productoIds))
            {
                var ids = productoIds.Split(',')
                    .Select(s => int.TryParse(s.Trim(), out var n) ? n : 0)
                    .Where(n => n > 0)
                    .Distinct();

                foreach (var pid in ids)
                {
                    _db.DropProductos.Add(new DropProducto { DropId = drop.Id, ProductoId = pid });
                }
                await _db.SaveChangesAsync();
            }

            return CreatedAtAction(nameof(GetDrop), new { id = drop.Id }, new { drop.Id, drop.Nombre, drop.ImagenUrl, drop.FechaCreacion });
        }

        // DELETE /api/drops/{id}  (Admin)
        [HttpDelete("{id}")]
        [Authorize(Roles = "Admin")]
        public async Task<IActionResult> EliminarDrop(int id)
        {
            var drop = await _db.Drops.FindAsync(id);
            if (drop == null) return NotFound();

            // Borrar imagen del disco
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
