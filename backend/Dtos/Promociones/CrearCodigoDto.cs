using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.Promociones
{
    public class CrearCodigoDto
    {
        [Required, StringLength(30, MinimumLength = 3)]
        public string Codigo { get; set; } = null!;

        [Required, RegularExpression("^(porcentaje|fijo)$")]
        public string Tipo { get; set; } = null!;

        [Required, Range(0.01, 100000)]
        public decimal Valor { get; set; }

        public DateTime? FechaExpiracion { get; set; }
        public int? UsosMaximos { get; set; }
    }
}
