using backend.Data;
using backend.Models;
using Microsoft.EntityFrameworkCore;
using backend.Helpers;

namespace backend.Services
{
    public class AuthService
    {
        private readonly AppDbContext _context;
        private readonly JwtHelper _jwtHelper;
        private readonly PasswordHelper _passwordHelper;

        public AuthService(
            AppDbContext context,
            JwtHelper jwtHelper,
            PasswordHelper passwordHelper
        )
        {
            _context = context;
            _jwtHelper = jwtHelper;
            _passwordHelper = passwordHelper;
        }

        public async Task<string?> Login(string email, string password)
        {
            var usuario = await _context.Usuarios
                .FirstOrDefaultAsync(u => u.Email == email);

            if (usuario == null)
                return null;

            var passwordValida = _passwordHelper.VerifyPassword(
                usuario,
                password,
                usuario.Password
            );

            if (!passwordValida)
                return null;

            return _jwtHelper.GenerarToken(usuario);
        }
    }
}
