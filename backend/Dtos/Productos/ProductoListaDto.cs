namespace backend.Dtos.Productos
{
    public class ProductoListaDto
    {
        public int Id { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public decimal Precio { get; set; }
        public int Stock { get; set; }
        public string Categoria { get; set; } = string.Empty;
        public string Estado { get; set; } = string.Empty;
        public string? Color { get; set; }
        public string VendedorNombre { get; set; } = string.Empty;
        public DateTime FechaPublicacion { get; set; }
        public string? ImagenPrincipalUrl { get; set; }
    }
}