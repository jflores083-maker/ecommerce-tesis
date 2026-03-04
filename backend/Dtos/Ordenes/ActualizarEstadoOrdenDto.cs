using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.Ordenes
{
    public class ActualizarEstadoOrdenDto
    {
        [Required] public string Estado { get; set; } = null!; // enviado, entregado, cancelado
        public string? NumeroSeguimiento { get; set; }
    }
}
