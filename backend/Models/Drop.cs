using System.ComponentModel.DataAnnotations;

namespace backend.Models
{
    public class Drop
    {
        public int Id { get; set; }

        [Required]
        [MaxLength(200)]
        public string Nombre { get; set; } = string.Empty;

        public string? ImagenUrl { get; set; }

        public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;

        public ICollection<DropProducto> DropProductos { get; set; } = new List<DropProducto>();
    }
}
