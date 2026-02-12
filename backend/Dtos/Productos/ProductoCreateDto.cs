using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.Productos
{
    public class ProductoCreateDto
    {
        [Required(ErrorMessage = "El título es obligatorio")]
        [MaxLength(200)]
        public string Titulo { get; set; } = string.Empty;

        [Required(ErrorMessage = "La descripción es obligatoria")]
        public string Descripcion { get; set; } = string.Empty;

        [Required(ErrorMessage = "El precio es obligatorio")]
        [Range(0.01, double.MaxValue, ErrorMessage = "El precio debe ser mayor a 0")]
        public decimal Precio { get; set; }

        [Required(ErrorMessage = "Los talles son obligatorios")]
        public string Talles { get; set; } = string.Empty; // JSON: ["S", "M", "L"]

        [Required(ErrorMessage = "La categoría es obligatoria")]
        [MaxLength(100)]
        public string Categoria { get; set; } = string.Empty;

        [MaxLength(50)]
        public string? Color { get; set; }

        public string Estado { get; set; } = "disponible";
    }
}