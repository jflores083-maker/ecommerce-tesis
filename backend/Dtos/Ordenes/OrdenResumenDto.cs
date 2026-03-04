using System;

namespace backend.Dtos.Ordenes
{
    public class OrdenResumenDto
    {
        public int OrdenId { get; set; }
        public string Estado { get; set; } = null!;
        public decimal Subtotal { get; set; }
        public decimal CostoEnvio { get; set; }
        public decimal Total { get; set; }
        public DateTime Fecha { get; set; }
    }
}