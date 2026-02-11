using backend.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using backend.Data;
using backend.Helpers;
using backend.Dtos.Usuarios;
using backend.Models;
using Microsoft.EntityFrameworkCore;
using backend.Dtos.Auth;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/auth")]
    public class AuthController : ControllerBase
    {
        private readonly AuthService _authService;
        private readonly AppDbContext _context;
        private readonly PasswordHelper _passwordHelper;

        public AuthController(
            AuthService authService,
            AppDbContext context,
            PasswordHelper passwordHelper)
        {
            _authService = authService;
            _context = context;
            _passwordHelper = passwordHelper;
        }

        [HttpPost("login")]
        [AllowAnonymous]
        public async Task<IActionResult> Login(LoginRequest request)
        {
            var token = await _authService.Login(request.Email, request.Password);

            if (token == null)
                return Unauthorized("Credenciales inválidas");

            return Ok(new { token });
        }

        [HttpPost("register")]
        [AllowAnonymous]
        public async Task<IActionResult> Register(UsuarioRegistroDto dto)
        {
            var existe = await _context.Usuarios.AnyAsync(u => u.Email == dto.Email);
            if (existe)
                return BadRequest("El email ya está registrado");

            var usuario = new Usuario
            {
                Nombre = dto.Nombre,
                Email = dto.Email,
                Rol = "Cliente"
            };

            usuario.Password = _passwordHelper.HashPassword(usuario, dto.Password);

            _context.Usuarios.Add(usuario);
            await _context.SaveChangesAsync();

            return Ok("Usuario registrado correctamente");
        }
    }
}
