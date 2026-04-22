using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.Auth
{
    public class ReenviarCodigoDto
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
    }
}
