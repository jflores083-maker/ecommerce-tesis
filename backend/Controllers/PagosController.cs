using backend.Data;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/pagos")]
    [Authorize]
    public class PagosController : ControllerBase
    {
        private readonly AppDbContext _context;

        public PagosController(AppDbContext context)
        {
            _context = context;
        }

        [HttpPost("iniciar")]
        public async Task<IActionResult> IniciarPago([FromBody] int ordenId)
        {
            var orden = await _context.Ordenes
            .FirstOrDefaultAsync(o => o.Id == ordenId);

            if (orden == null)
                return NotFound("Orden no encontrada");

            if (orden.Estado != "pendiente")
                return BadRequest("La orden no está en estado pendiente");

            var yaTienePago = await _context.Pagos
                .AnyAsync(p => p.OrdenId == ordenId);

            if (yaTienePago)
                return BadRequest("La orden ya tiene un pago iniciado");

            var pago = new Pago
            {
                OrdenId = orden.Id,
                Monto = orden.Total,
                Metodo = "mercadopago",
                Estado = "pendiente"
            };

            _context.Pagos.Add(pago);
            await _context.SaveChangesAsync();

            return Ok(new
            {
                pago.Id,
                pago.Estado,
                pago.Monto
            });
        }
    }
}