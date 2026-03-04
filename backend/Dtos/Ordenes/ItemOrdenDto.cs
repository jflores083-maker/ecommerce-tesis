namespace backend.Dtos.Ordenes
{
    public class ItemOrdenDto
    {
        public int ProductoId { get; set; }
        public string Titulo { get; set; } = null!;
        public string Talle { get; set; } = null!;
        public int Cantidad { get; set; }
        public decimal PrecioUnitario { get; set; } // congelado
        public decimal Subtotal { get; set; }
    }
}