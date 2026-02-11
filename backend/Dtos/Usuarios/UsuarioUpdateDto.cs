using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.Usuarios
{
    public class UsuarioUpdateDto
    {
        [Required]
        public string Nombre { get; set; } = string.Empty;

        [Required]
        public string Apellido { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string Telefono { get; set; } = string.Empty;

        public string? Password { get; set; }
    }
}
