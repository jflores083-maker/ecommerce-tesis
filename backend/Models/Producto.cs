using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace backend.Models
{
    public class Producto
    {
        public int Id { get; set; }

        [Required]
        public int VendedorId { get; set; }

        [Required]
        [MaxLength(200)]
        public string Titulo { get; set; } = string.Empty;

        [Required]
        public string Descripcion { get; set; } = string.Empty;

        [Required]
        [Column(TypeName = "decimal(10,2)")]
        public decimal Precio { get; set; }

        public int Stock { get; set; } = 0;

        [Required]
        public string Talles { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string Categoria { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string Estado { get; set; } = "disponible";

        [MaxLength(50)]
        public string? Color { get; set; }

        public DateTime FechaPublicacion { get; set; } = DateTime.Now;

        public bool Activo { get; set; } = true;

        [ForeignKey("VendedorId")]
        public Usuario Vendedor { get; set; } = null!;

        public ICollection<ImagenProducto> Imagenes { get; set; } = new List<ImagenProducto>();
    }
}