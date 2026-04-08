using backend.Data;
using backend.Dtos.Promociones;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/promociones")]
    public class PromocionesController : ControllerBase
    {
        private readonly AppDbContext _db;

        public PromocionesController(AppDbContext db)
        {
            _db = db;
        }

        // GET /api/promociones  — lista todos (solo admin)
        [HttpGet]
        [Authorize]
        public async Task<IActionResult> Listar()
        {
            var codigos = await _db.CodigosPromocion
                .OrderByDescending(c => c.FechaCreacion)
                .Select(c => new
                {
                    c.Id,
                    c.Codigo,
                    c.Tipo,
                    c.Valor,
                    c.Activo,
                    c.FechaExpiracion,
                    c.UsosMaximos,
                    c.UsosActuales,
                    c.FechaCreacion
                })
                .ToListAsync();

            return Ok(codigos);
        }

        // POST /api/promociones  — crear (solo admin)
        [HttpPost]
        [Authorize]
        public async Task<IActionResult> Crear([FromBody] CrearCodigoDto dto)
        {
            if (!ModelState.IsValid) return ValidationProblem(ModelState);

            var codigoNormalizado = dto.Codigo.Trim().ToUpperInvariant();

            var existe = await _db.CodigosPromocion
                .AnyAsync(c => c.Codigo == codigoNormalizado);

            if (existe)
                return Conflict(new { message = "Ya existe un código con ese nombre." });

            if (dto.Tipo == "porcentaje" && dto.Valor > 100)
                return BadRequest(new { message = "El porcentaje no puede superar 100." });

            var codigo = new CodigoPromocion
            {
                Codigo = codigoNormalizado,
                Tipo = dto.Tipo,
                Valor = dto.Valor,
                FechaExpiracion = dto.FechaExpiracion,
                UsosMaximos = dto.UsosMaximos
            };

            _db.CodigosPromocion.Add(codigo);
            await _db.SaveChangesAsync();

            return CreatedAtAction(nameof(Listar), new { id = codigo.Id }, new { codigo.Id, codigo.Codigo });
        }

        // DELETE /api/promociones/{id}  — eliminar (solo admin)
        [HttpDelete("{id:int}")]
        [Authorize]
        public async Task<IActionResult> Eliminar(int id)
        {
            var codigo = await _db.CodigosPromocion.FindAsync(id);
            if (codigo == null) return NotFound();

            _db.CodigosPromocion.Remove(codigo);
            await _db.SaveChangesAsync();

            return NoContent();
        }

        // POST /api/promociones/validar  — valida y calcula descuento (usuario autenticado)
        [HttpPost("validar")]
        [Authorize]
        public async Task<ActionResult<ValidarCodigoResponseDto>> Validar([FromBody] ValidarCodigoRequestDto dto)
        {
            if (!ModelState.IsValid) return ValidationProblem(ModelState);

            var codigoNormalizado = dto.Codigo.Trim().ToUpperInvariant();

            var codigo = await _db.CodigosPromocion
                .FirstOrDefaultAsync(c => c.Codigo == codigoNormalizado && c.Activo);

            if (codigo == null)
                return BadRequest(new { message = "Código inválido o inactivo." });

            if (codigo.FechaExpiracion.HasValue && codigo.FechaExpiracion < DateTime.UtcNow)
                return BadRequest(new { message = "El código ha expirado." });

            if (codigo.UsosMaximos.HasValue && codigo.UsosActuales >= codigo.UsosMaximos)
                return BadRequest(new { message = "El código ya alcanzó su límite de usos." });

            var descuento = codigo.Tipo == "porcentaje"
                ? Math.Round(dto.Subtotal * codigo.Valor / 100, 2)
                : Math.Min(codigo.Valor, dto.Subtotal);

            return Ok(new ValidarCodigoResponseDto
            {
                Codigo = codigo.Codigo,
                Tipo = codigo.Tipo,
                Valor = codigo.Valor,
                Descuento = descuento,
                TotalFinal = dto.Subtotal - descuento
            });
        }
    }
}
