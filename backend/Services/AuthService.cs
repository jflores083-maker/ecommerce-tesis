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

        public AuthService(AppDbContext context, JwtHelper jwtHelper)
        {
            _context = context;
            _jwtHelper = jwtHelper;
        }

        public async Task<string?> Login(string email, string password)
        {
            var usuario = await _context.Usuarios
                .FirstOrDefaultAsync(u => u.Email == email && u.Password == password);

            if (usuario == null)
                return null;

            return _jwtHelper.GenerarToken(usuario);
        }
    }
}
