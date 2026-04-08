using backend.Data;
using backend.Dtos.Dashboard;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/dashboard")]
    [Authorize(Roles = "Admin")]
    public class DashboardController : ControllerBase
    {
        private readonly AppDbContext _db;
        private static readonly string[] _meses =
            { "Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic" };

        public DashboardController(AppDbContext db)
        {
            _db = db;
        }

        // GET /api/dashboard
        [HttpGet]
        public async Task<ActionResult<DashboardDto>> Get()
        {
            var ahora = DateTime.UtcNow;
            var hoy   = ahora.Date;
            var estadosVenta = new[] { "pagado", "enviado", "entregado" };

            // ── Tarjetas resumen ──────────────────────────────
            var ordenesVenta = await _db.Ordenes
                .Where(o => estadosVenta.Contains(o.Estado))
                .ToListAsync();

            var totalVentas    = ordenesVenta.Sum(o => o.Total);
            var totalOrdenes   = ordenesVenta.Count;
            var ordenesHoy     = ordenesVenta.Count(o => o.FechaCreacion.Date == hoy);
            var productosActivos = await _db.Productos.CountAsync(p => p.Activo);

            // ── Ventas por mes (últimos 6 meses) ─────────────
            var desde = new DateTime(ahora.Year, ahora.Month, 1).AddMonths(-5);
            var ventasPorMes = ordenesVenta
                .Where(o => o.FechaCreacion >= desde)
                .GroupBy(o => new { o.FechaCreacion.Year, o.FechaCreacion.Month })
                .Select(g => new VentaMensualDto
                {
                    Anio     = g.Key.Year,
                    Mes      = g.Key.Month,
                    MesNombre = _meses[g.Key.Month - 1],
                    Total    = g.Sum(o => o.Total),
                    Ordenes  = g.Count()
                })
                .OrderBy(v => v.Anio).ThenBy(v => v.Mes)
                .ToList();

            // Rellenar meses sin ventas para que el gráfico sea continuo
            var mesesCompletos = new List<VentaMensualDto>();
            for (int i = 0; i < 6; i++)
            {
                var mes = desde.AddMonths(i);
                var existente = ventasPorMes.FirstOrDefault(v => v.Anio == mes.Year && v.Mes == mes.Month);
                mesesCompletos.Add(existente ?? new VentaMensualDto
                {
                    Anio      = mes.Year,
                    Mes       = mes.Month,
                    MesNombre = _meses[mes.Month - 1],
                    Total     = 0,
                    Ordenes   = 0
                });
            }

            // ── Órdenes recientes ─────────────────────────────
            var ordenesRecientes = await _db.Ordenes
                .OrderByDescending(o => o.FechaCreacion)
                .Take(8)
                .Select(o => new OrdenResumenDashboardDto
                {
                    OrdenId = o.Id,
                    Estado  = o.Estado,
                    Total   = o.Total,
                    Fecha   = o.FechaCreacion
                })
                .ToListAsync();

            // ── Producto más vendido ──────────────────────────
            var productoTop = await _db.ItemsOrden
                .Where(i => estadosVenta.Contains(i.Orden.Estado))
                .GroupBy(i => i.ProductoId)
                .Select(g => new
                {
                    ProductoId       = g.Key,
                    UnidadesVendidas = g.Sum(i => i.Cantidad),
                    TotalGenerado    = g.Sum(i => i.Subtotal)
                })
                .OrderByDescending(g => g.UnidadesVendidas)
                .Join(_db.Productos,
                    g => g.ProductoId,
                    p => p.Id,
                    (g, p) => new ProductoTopDto
                    {
                        Id               = p.Id,
                        Titulo           = p.Titulo,
                        UnidadesVendidas = g.UnidadesVendidas,
                        TotalGenerado    = g.TotalGenerado
                    })
                .FirstOrDefaultAsync();

            // ── Productos con bajo stock ──────────────────────
            var bajoStock = await _db.Productos
                .Where(p => p.Activo && p.Stock <= 5)
                .OrderBy(p => p.Stock)
                .Take(6)
                .Select(p => new ProductoBajoStockDto
                {
                    Id        = p.Id,
                    Titulo    = p.Titulo,
                    Categoria = p.Categoria,
                    Stock     = p.Stock
                })
                .ToListAsync();

            return Ok(new DashboardDto
            {
                TotalVentas      = totalVentas,
                TotalOrdenes     = totalOrdenes,
                OrdenesHoy       = ordenesHoy,
                ProductosActivos = productosActivos,
                VentasPorMes     = mesesCompletos,
                OrdenesRecientes = ordenesRecientes,
                ProductoTop      = productoTop,
                ProductosBajoStock = bajoStock
            });
        }
    }
}
