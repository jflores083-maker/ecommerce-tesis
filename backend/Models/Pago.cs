using System;

namespace backend.Models
{
    public class Pago
    {
        public int Id { get; set; }

        // Relación 1 a 1 con Orden
        public int OrdenId { get; set; }
        public Orden Orden { get; set; } = null!;

        // Datos del pago
        public decimal Monto { get; set; }
        public string Metodo { get; set; } = null!; // ej: "mercadopago"
        public string Estado { get; set; } = null!; // pendiente | aprobado | rechazado | cancelado

        // Identificador externo (Mercado Pago)
        public string? TransaccionId { get; set; }

        // Fechas
        public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
        public DateTime? FechaPago { get; set; }
    }
}