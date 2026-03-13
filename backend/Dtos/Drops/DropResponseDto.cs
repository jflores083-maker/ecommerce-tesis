namespace backend.Dtos.Drops
{
    public class DropResponseDto
    {
        public int Id { get; set; }
        public string Nombre { get; set; } = string.Empty;
        public string? ImagenUrl { get; set; }
        public DateTime FechaCreacion { get; set; }
        public List<DropProductoDto> Productos { get; set; } = new();
    }

    public class DropProductoDto
    {
        public int Id { get; set; }
        public string Titulo { get; set; } = string.Empty;
        public decimal Precio { get; set; }
        public string Estado { get; set; } = string.Empty;
        public string? ImagenUrl { get; set; }
    }
}
