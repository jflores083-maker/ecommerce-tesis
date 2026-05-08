using backend.Data;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/favoritos")]
    [Authorize]
    public class FavoritosController : ControllerBase
    {
        private readonly AppDbContext _context;

        public FavoritosController(AppDbContext context)
        {
            _context = context;
        }

        private int GetUserId() =>
            int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // GET api/favoritos
        [HttpGet]
        public async Task<IActionResult> GetFavoritos()
        {
            var userId = GetUserId();
            var favoritos = await _context.Favoritos
                .Where(f => f.UsuarioId == userId)
                .Include(f => f.Producto)
                    .ThenInclude(p => p.Imagenes)
                .OrderByDescending(f => f.FechaAgregado)
                .Select(f => new
                {
                    f.Id,
                    f.ProductoId,
                    f.FechaAgregado,
                    Producto = new
                    {
                        f.Producto.Id,
                        f.Producto.Titulo,
                        f.Producto.Precio,
                        f.Producto.Estado,
                        f.Producto.Categoria,
                        f.Producto.Stock,
                        ImagenPrincipal = f.Producto.Imagenes
                            .OrderBy(i => i.Orden)
                            .Select(i => i.Url)
                            .FirstOrDefault()
                    }
                })
                .ToListAsync();

            return Ok(favoritos);
        }

        // POST api/favoritos/{productoId}
        [HttpPost("{productoId}")]
        public async Task<IActionResult> Agregar(int productoId)
        {
            var userId = GetUserId();

            var producto = await _context.Productos.FindAsync(productoId);
            if (producto == null)
                return NotFound("Producto no encontrado");

            var yaExiste = await _context.Favoritos
                .AnyAsync(f => f.UsuarioId == userId && f.ProductoId == productoId);

            if (yaExiste)
                return Conflict("El producto ya está en favoritos");

            var favorito = new Favorito
            {
                UsuarioId = userId,
                ProductoId = productoId
            };

            _context.Favoritos.Add(favorito);
            await _context.SaveChangesAsync();

            return Ok(new { favoritoId = favorito.Id, productoId });
        }

        // DELETE api/favoritos/{productoId}
        [HttpDelete("{productoId}")]
        public async Task<IActionResult> Eliminar(int productoId)
        {
            var userId = GetUserId();

            var favorito = await _context.Favoritos
                .FirstOrDefaultAsync(f => f.UsuarioId == userId && f.ProductoId == productoId);

            if (favorito == null)
                return NotFound("Favorito no encontrado");

            _context.Favoritos.Remove(favorito);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        // GET api/favoritos/check/{productoId}
        [HttpGet("check/{productoId}")]
        public async Task<IActionResult> Check(int productoId)
        {
            var userId = GetUserId();
            var esFavorito = await _context.Favoritos
                .AnyAsync(f => f.UsuarioId == userId && f.ProductoId == productoId);

            return Ok(new { esFavorito });
        }
    }
}