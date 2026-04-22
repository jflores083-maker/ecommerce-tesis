using System;
using System.Collections.Generic;

namespace backend.Dtos.Ordenes
{
    public class OrdenDetalleDto
    {
        public int OrdenId { get; set; }
        public string Estado { get; set; } = null!;
        public string? NumeroSeguimiento { get; set; }
        public string DireccionEnvio { get; set; } = null!;
        public string Ciudad { get; set; } = null!;
        public string CodigoPostal { get; set; } = null!;
        public decimal Subtotal { get; set; }
        public decimal CostoEnvio { get; set; }
        public decimal Total { get; set; }
        public DateTime Fecha { get; set; }
        public List<ItemOrdenDto> Items { get; set; } = new();
    }
}