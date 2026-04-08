using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.Promociones
{
    public class ValidarCodigoRequestDto
    {
        [Required] public string Codigo { get; set; } = null!;
        [Required, Range(0.01, double.MaxValue)] public decimal Subtotal { get; set; }
    }

    public class ValidarCodigoResponseDto
    {
        public string Codigo { get; set; } = null!;
        public string Tipo { get; set; } = null!;
        public decimal Valor { get; set; }
        public decimal Descuento { get; set; }    // monto calculado
        public decimal TotalFinal { get; set; }
    }
}
