namespace backend.Dtos.Carrito
{
    public class ItemCarritoDto
    {
        public int Id { get; set; }
        public int ProductoId { get; set; }
        public string Titulo { get; set; } = null!;
        public string? ImagenPrincipalUrl { get; set; }
        public string Talle { get; set; } = null!;
        public int Cantidad { get; set; }
        public decimal PrecioUnitarioVigente { get; set; }
        public decimal Subtotal => Cantidad * PrecioUnitarioVigente;
    }
}