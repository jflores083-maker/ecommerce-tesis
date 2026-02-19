using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.Carrito
{
    public class AgregarItemCarritoDto
    {
        [Required(ErrorMessage = "El ID del producto es obligatorio")]
        public int ProductoId { get; set; }

        [Required(ErrorMessage = "La cantidad es obligatoria")]
        [Range(1, 100, ErrorMessage = "La cantidad debe estar entre 1 y 100")]
        public int Cantidad { get; set; }

        [Required(ErrorMessage = "El talle es obligatorio")]
        [MaxLength(10)]
        public string Talle { get; set; } = string.Empty;
    }
}