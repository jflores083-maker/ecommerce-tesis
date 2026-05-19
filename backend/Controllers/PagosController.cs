using backend.Data;
using backend.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using backend.Services;
using System.Text.Json;
using backend.Options;
using Microsoft.Extensions.Options;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/pagos")]
    [Authorize]
    public class PagosController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly MercadoPagoService _mercadoPagoService;
        private readonly MercadoPagoOptions _options;
        private readonly EmailService _emailService;
        public PagosController(
            AppDbContext context,
            MercadoPagoService mercadoPagoService,
            IOptions<MercadoPagoOptions> options,
            EmailService emailService)
        {
            _context = context;
            _mercadoPagoService = mercadoPagoService;
            _options = options.Value;
            _emailService = emailService;
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

            var initPoint = await _mercadoPagoService.CrearPreferenciaAsync(
                orden.Id,
                orden.Total,
                $"Orden #{orden.Id}"
            );

            // persistimos el pago en la DB
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
                pagoId = pago.Id,
                initPoint
            });
        }
        [HttpPost("efectivo")]
        public async Task<IActionResult> PagarEfectivo([FromBody] int ordenId)
        {
            var orden = await _context.Ordenes
                .Include(o => o.Comprador)
                .FirstOrDefaultAsync(o => o.Id == ordenId);

            if (orden == null) return NotFound("Orden no encontrada.");
            if (orden.Estado != "pendiente") return BadRequest("La orden no está en estado pendiente.");

            var yaTienePago = await _context.Pagos.AnyAsync(p => p.OrdenId == ordenId);
            if (yaTienePago) return BadRequest("La orden ya tiene un pago registrado.");

            var pago = new Pago
            {
                OrdenId = orden.Id,
                Monto   = orden.Total,
                Metodo  = "efectivo",
                Estado  = "pendiente"
            };
            _context.Pagos.Add(pago);
            await _context.SaveChangesAsync();

            if (orden.Comprador != null)
            {
                var cuerpo = _emailService.TemplateEfectivoPendiente(orden.Id, orden.Total);
                await _emailService.EnviarEmailAsync(
                    orden.Comprador.Email,
                    $"📦 Pedido #{orden.Id} reservado - Pasá a abonar en Urbal",
                    cuerpo
                );
            }

            return Ok(new { pagoId = pago.Id });
        }

        [HttpPost("webhook")]
        [AllowAnonymous]
        public async Task<IActionResult> Webhook(
            [FromQuery] string? type,
            [FromQuery(Name = "data.id")] string? dataId,
            [FromHeader(Name = "x-signature")] string? signature,
            [FromHeader(Name = "x-request-id")] string? requestId)
        {
            // Validar firma de MercadoPago
            /*if (!string.IsNullOrEmpty(signature) && !string.IsNullOrEmpty(_options.WebhookSecret))
            {
                var ts = "";
                var v1 = "";

                foreach (var part in signature.Split(','))
                {
                    var kv = part.Split('=');
                    if (kv.Length == 2)
                    {
                        if (kv[0].Trim() == "ts") ts = kv[1].Trim();
                        if (kv[0].Trim() == "v1") v1 = kv[1].Trim();
                    }
                }

                var manifest = $"id:{dataId};request-id:{requestId};ts:{ts};";
                var secretBytes = System.Text.Encoding.UTF8.GetBytes(_options.WebhookSecret);
                var manifestBytes = System.Text.Encoding.UTF8.GetBytes(manifest);

                using var hmac = new System.Security.Cryptography.HMACSHA256(secretBytes);
                var hash = hmac.ComputeHash(manifestBytes);
                var computed = BitConverter.ToString(hash).Replace("-", "").ToLower();

                if (computed != v1)
                    return Unauthorized("Firma inválida");
            }*/

            if (type != "payment" || string.IsNullOrEmpty(dataId))
                return Ok();

            JsonElement pagoMp;
            try
            {
                pagoMp = await _mercadoPagoService.ObtenerPagoAsync(dataId);
            }
            catch
            {
                return Ok();
            }

            var estado = pagoMp.GetProperty("status").GetString();
            var externalReference = pagoMp.GetProperty("external_reference").GetString();
            Console.WriteLine($"🔔 WEBHOOK - Estado MP: {estado}, OrdenId: {externalReference}"); 
            if (!int.TryParse(externalReference, out int ordenId))
                return Ok();

            var pago = await _context.Pagos
                .Include(p => p.Orden)
                .FirstOrDefaultAsync(p => p.OrdenId == ordenId);

            if (pago == null)
                return Ok();

            if (estado == "approved")
                {
                    pago.Estado = "aprobado";
                    pago.TransaccionId = dataId;
                    pago.FechaPago = DateTime.UtcNow;
                    pago.Orden.Estado = "pagado";

                    // Descontar stock por cada item de la orden
                    var items = await _context.ItemsOrden
                        .Include(i => i.Producto)
                        .Where(i => i.OrdenId == ordenId)
                        .ToListAsync();

                    foreach (var item in items)
                    {
                        item.Producto.Stock -= item.Cantidad;

                        // Si el stock llega a 0, marcamos el producto como agotado
                        if (item.Producto.Stock <= 0)
                        {
                            item.Producto.Stock = 0;
                            item.Producto.Estado = "agotado";
                        }
                    }

                    // Enviar email de confirmación al comprador
                    var comprador = await _context.Usuarios
                        .FirstOrDefaultAsync(u => u.Id == pago.Orden.CompradorId);

                    if (comprador != null)
                    {
                        var cuerpo = _emailService.TemplateOrdenConfirmada(ordenId, pago.Monto);
                        await _emailService.EnviarEmailAsync(
                            comprador.Email,
                            $"✅ Orden #{ordenId} confirmada - Urbal",
                            cuerpo
                        );
                    }
                }
            else if (estado == "rejected" || estado == "cancelled")
            {
                pago.Estado = "rechazado";
                pago.Orden.Estado = "cancelado";

                var comprador = await _context.Usuarios
                    .FirstOrDefaultAsync(u => u.Id == pago.Orden.CompradorId);

                if (comprador != null)
                {
                    var cuerpo = _emailService.TemplateOrdenCancelada(ordenId);
                    await _emailService.EnviarEmailAsync(
                        comprador.Email,
                        $"Tu orden #{ordenId} fue cancelada - Urbal",
                        cuerpo
                    );
                }
            }

            await _context.SaveChangesAsync();
            return Ok();
        }
    }
}