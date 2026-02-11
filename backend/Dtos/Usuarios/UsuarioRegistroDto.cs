using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.Usuarios
{
    public class UsuarioRegistroDto
    {
        [Required]
        public string Nombre { get; set; } = string.Empty;

        [Required]
        public string Apellido { get; set; } = string.Empty;

        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        [RegularExpression(@"^\+54\d{10,12}$",
            ErrorMessage = "El telefono debe comenzar con +54 y contener solo numeros.")]
        public string Telefono { get; set; } = string.Empty;

        [Required]
        [MinLength(6)]
        public string Password { get; set; } = string.Empty;
    }
}
