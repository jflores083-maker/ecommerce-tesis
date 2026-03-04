namespace backend.Models
{
    public class ItemOrden
    {
        public int Id { get; set; }
        public int OrdenId { get; set; }
        public int ProductoId { get; set; }

        public int Cantidad { get; set; }
        public string Talle { get; set; } = null!;

        // ⚠️ Precio congelado al momento de compra
        public decimal PrecioUnitario { get; set; }
        public decimal Subtotal { get; set; } // Cantidad * PrecioUnitario

        // Nav
        public Orden Orden { get; set; } = null!;
        public Producto Producto { get; set; } = null!;
    }
}