using Microsoft.AspNetCore.Identity;
using backend.Models;

namespace backend.Helpers
{
    public class PasswordHelper
    {
        private readonly PasswordHasher<Usuario> _hasher = new();

        public string HashPassword(Usuario usuario, string password)
        {
            return _hasher.HashPassword(usuario, password);
        }

        public bool VerifyPassword(Usuario usuario, string password, string hash)
        {
            var result = _hasher.VerifyHashedPassword(usuario, hash, password);
            return result == PasswordVerificationResult.Success;
        }
    }
}
