using System.ComponentModel.DataAnnotations.Schema;

namespace backend.Models
{
    public class DropProducto
    {
        public int DropId { get; set; }
        public int ProductoId { get; set; }

        [ForeignKey("DropId")]
        public Drop Drop { get; set; } = null!;

        [ForeignKey("ProductoId")]
        public Producto Producto { get; set; } = null!;
    }
}
