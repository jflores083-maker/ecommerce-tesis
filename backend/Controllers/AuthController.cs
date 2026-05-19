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
        private readonly EmailService _emailService;
        private readonly JwtHelper _jwtHelper;

        public AuthController(
            AuthService authService,
            AppDbContext context,
            PasswordHelper passwordHelper,
            EmailService emailService,
            JwtHelper jwtHelper)
        {
            _authService = authService;
            _context = context;
            _passwordHelper = passwordHelper;
            _emailService = emailService;
            _jwtHelper = jwtHelper;
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
            if (!ModelState.IsValid)
            {
                var errores = ModelState.Values
                    .SelectMany(v => v.Errors)
                    .Select(e => e.ErrorMessage)
                    .ToList();
                return BadRequest(string.Join(" | ", errores));
            }

            var existe = await _context.Usuarios.AnyAsync(u => u.Email == dto.Email);
            if (existe)
                return BadRequest("El email ya está registrado");

            if (!EsPasswordValida(dto.Password))
                return BadRequest("La contraseña debe tener al menos una mayúscula, una minúscula, un número y un símbolo.");

            var codigo = new Random().Next(100000, 999999).ToString();

            var usuario = new Usuario
            {
                Nombre       = dto.Nombre,
                Apellido     = dto.Apellido,
                Email        = dto.Email,
                Telefono     = dto.Telefono,
                Rol          = "Cliente",
                EmailConfirmado   = false,
                CodigoVerificacion = codigo,
                CodigoExpiracion   = DateTime.UtcNow.AddMinutes(15)
            };

            usuario.Password = _passwordHelper.HashPassword(usuario, dto.Password);

            _context.Usuarios.Add(usuario);
            await _context.SaveChangesAsync();

            var cuerpo = _emailService.TemplateVerificacionEmail(dto.Nombre, codigo);
            await _emailService.EnviarEmailAsync(
                dto.Email,
                "Tu código de verificación - Urbal",
                cuerpo
            );

            return Ok(new { email = dto.Email });
        }

        [HttpPost("verificar")]
        [AllowAnonymous]
        public async Task<IActionResult> VerificarEmail(VerificarEmailDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var usuario = await _context.Usuarios
                .FirstOrDefaultAsync(u => u.Email == dto.Email);

            if (usuario == null)
                return BadRequest("Email no encontrado");

            if (usuario.EmailConfirmado)
                return BadRequest("El email ya fue confirmado");

            if (usuario.CodigoVerificacion != dto.Codigo)
                return BadRequest("Código incorrecto");

            if (usuario.CodigoExpiracion == null || usuario.CodigoExpiracion < DateTime.UtcNow)
                return BadRequest("El código expiró. Solicitá uno nuevo");

            usuario.EmailConfirmado    = true;
            usuario.CodigoVerificacion = null;
            usuario.CodigoExpiracion   = null;

            await _context.SaveChangesAsync();

            var token = _jwtHelper.GenerarToken(usuario);
            return Ok(new { token });
        }

        [HttpPost("reenviar-codigo")]
        [AllowAnonymous]
        public async Task<IActionResult> ReenviarCodigo(ReenviarCodigoDto dto)
        {
            if (!ModelState.IsValid) return BadRequest(ModelState);

            var usuario = await _context.Usuarios
                .FirstOrDefaultAsync(u => u.Email == dto.Email);

            if (usuario == null)
                return BadRequest("Email no encontrado");

            if (usuario.EmailConfirmado)
                return BadRequest("El email ya fue confirmado");

            var codigo = new Random().Next(100000, 999999).ToString();
            usuario.CodigoVerificacion = codigo;
            usuario.CodigoExpiracion   = DateTime.UtcNow.AddMinutes(15);

            await _context.SaveChangesAsync();

            var cuerpo = _emailService.TemplateVerificacionEmail(usuario.Nombre, codigo);
            await _emailService.EnviarEmailAsync(
                dto.Email,
                "Tu código de verificación - Urbal",
                cuerpo
            );

            return Ok("Código reenviado");
        }

        private static bool EsPasswordValida(string password) =>
            password.Any(char.IsUpper) &&
            password.Any(char.IsLower) &&
            password.Any(char.IsDigit) &&
            password.Any(c => !char.IsLetterOrDigit(c));
    }
}
