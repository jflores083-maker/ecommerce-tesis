using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace backend.Models
{
    public class ImagenProducto
    {
        public int Id { get; set; }

        [Required]
        public int ProductoId { get; set; }

        [Required]
        [MaxLength(500)]
        public string Url { get; set; } = string.Empty;

        public int Orden { get; set; } = 0;

        public DateTime FechaSubida { get; set; } = DateTime.Now;

        [ForeignKey("ProductoId")]
        public Producto Producto { get; set; } = null!;
    }
}
