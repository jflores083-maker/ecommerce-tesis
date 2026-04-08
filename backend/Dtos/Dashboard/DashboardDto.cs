namespace backend.Dtos.Dashboard
{
    public class DashboardDto
    {
        // ── Tarjetas resumen ──────────────────────────────────
        public decimal TotalVentas { get; set; }
        public int TotalOrdenes { get; set; }
        public int OrdenesHoy { get; set; }
        public int ProductosActivos { get; set; }

        // ── Ventas por mes (últimos 6 meses) ─────────────────
        public List<VentaMensualDto> VentasPorMes { get; set; } = new();

        // ── Órdenes recientes ─────────────────────────────────
        public List<OrdenResumenDashboardDto> OrdenesRecientes { get; set; } = new();

        // ── Producto más vendido ──────────────────────────────
        public ProductoTopDto? ProductoTop { get; set; }

        // ── Productos con bajo stock ──────────────────────────
        public List<ProductoBajoStockDto> ProductosBajoStock { get; set; } = new();
    }

    public class VentaMensualDto
    {
        public int Anio { get; set; }
        public int Mes { get; set; }
        public string MesNombre { get; set; } = null!;
        public decimal Total { get; set; }
        public int Ordenes { get; set; }
    }

    public class OrdenResumenDashboardDto
    {
        public int OrdenId { get; set; }
        public string Estado { get; set; } = null!;
        public decimal Total { get; set; }
        public DateTime Fecha { get; set; }
    }

    public class ProductoTopDto
    {
        public int Id { get; set; }
        public string Titulo { get; set; } = null!;
        public int UnidadesVendidas { get; set; }
        public decimal TotalGenerado { get; set; }
    }

    public class ProductoBajoStockDto
    {
        public int Id { get; set; }
        public string Titulo { get; set; } = null!;
        public string Categoria { get; set; } = null!;
        public int Stock { get; set; }
    }
}
