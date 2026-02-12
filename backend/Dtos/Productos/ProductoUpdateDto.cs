using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.Productos
{
    public class ProductoUpdateDto
    {
        [MaxLength(200)]
        public string? Titulo { get; set; }

        public string? Descripcion { get; set; }

        [Range(0.01, double.MaxValue, ErrorMessage = "El precio debe ser mayor a 0")]
        public decimal? Precio { get; set; }

        public string? Talles { get; set; }

        [MaxLength(100)]
        public string? Categoria { get; set; }

        [MaxLength(50)]
        public string? Color { get; set; }

        [MaxLength(50)]
        public string? Estado { get; set; }

        public bool? Activo { get; set; }
    }
}