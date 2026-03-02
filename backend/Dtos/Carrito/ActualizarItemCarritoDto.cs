using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.Carrito
{
    public class ActualizarItemCarritoDto
    {
        [Required(ErrorMessage = "La cantidad es obligatoria")]
        [Range(1, 100, ErrorMessage = "La cantidad debe estar entre 1 y 100")]
        public int Cantidad { get; set; }
    }
}