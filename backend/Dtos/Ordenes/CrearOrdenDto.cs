using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.Ordenes
{
    public class CrearOrdenDto
    {
        [Required] public string DireccionEnvio { get; set; } = null!;
        [Required] public string Ciudad { get; set; } = null!;
        [Required] public string CodigoPostal { get; set; } = null!;
        public bool EsRetiro { get; set; }
        public string? MetodoPago { get; set; }
        public string? CodigoPromocion { get; set; }
    }
}
