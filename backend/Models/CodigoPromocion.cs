namespace backend.Models
{
    public class CodigoPromocion
    {
        public int Id { get; set; }

        public string Codigo { get; set; } = null!;          // ej: "VERANO10"
        public string Tipo { get; set; } = null!;             // "porcentaje" | "fijo"
        public decimal Valor { get; set; }                    // 10 = 10% o $10.000 fijos
        public bool Activo { get; set; } = true;

        public DateTime? FechaExpiracion { get; set; }
        public int? UsosMaximos { get; set; }                 // null = ilimitado
        public int UsosActuales { get; set; } = 0;

        public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
    }
}
