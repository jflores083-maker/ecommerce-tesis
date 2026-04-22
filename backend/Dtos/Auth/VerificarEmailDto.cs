using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.Auth
{
    public class VerificarEmailDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;

        [Required]
        public string Codigo { get; set; } = string.Empty;
    }
}
