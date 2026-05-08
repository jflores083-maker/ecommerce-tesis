using System.ComponentModel.DataAnnotations.Schema;

namespace backend.Models
{
    public class Favorito
    {
        public int Id { get; set; }
        public int UsuarioId { get; set; }
        public int ProductoId { get; set; }
        public DateTime FechaAgregado { get; set; } = DateTime.UtcNow;

        [ForeignKey("UsuarioId")]
        public Usuario Usuario { get; set; } = null!;

        [ForeignKey("ProductoId")]
        public Producto Producto { get; set; } = null!;
    }
}