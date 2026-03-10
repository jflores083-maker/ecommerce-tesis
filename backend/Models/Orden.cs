using System;
using System.Collections.Generic;

namespace backend.Models
{
    public class Orden
    {
        public int Id { get; set; }
        public int CompradorId { get; set; }
        public string Estado { get; set; } = "pendiente"; // pendiente, pagado, enviado, entregado, cancelado

        public decimal Subtotal { get; set; }
        public decimal CostoEnvio { get; set; }
        public decimal Total { get; set; }

        public string DireccionEnvio { get; set; } = null!;
        public string Ciudad { get; set; } = null!;
        public string CodigoPostal { get; set; } = null!;

        public string? NumeroSeguimiento { get; set; }

        public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
        public DateTime FechaActualizacion { get; set; } = DateTime.UtcNow;

        // Nav
        public Usuario Comprador { get; set; } = null!;
        public ICollection<ItemOrden> Items { get; set; } = new List<ItemOrden>();

        // public Pago? Pago { get; set; } // <-- SE AGREGARÁ EN EL MÓDULO PAGOS (ahora no)
    }
}