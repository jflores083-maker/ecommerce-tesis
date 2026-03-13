using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.Usuarios
{
    public class ActualizarPerfilDto
    {
        [Required]
        public string Nombre { get; set; } = string.Empty;

        [Required]
        public string Apellido { get; set; } = string.Empty;

        [Required]
        public string Telefono { get; set; } = string.Empty;

        // Solo requerido si se quiere cambiar la contraseña
        public string? PasswordActual { get; set; }
        public string? PasswordNueva { get; set; }
    }
}
