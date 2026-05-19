using backend.Data;
using backend.Dtos.Usuarios;
using backend.Models;
using backend.Helpers;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/usuarios")]
    [Authorize]
    public class UsuarioController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly PasswordHelper _passwordHelper;
        private readonly IWebHostEnvironment _env;

        public UsuarioController(AppDbContext context, PasswordHelper passwordHelper, IWebHostEnvironment env)
        {
            _context = context;
            _passwordHelper = passwordHelper;
            _env = env;
        }

        // Devuelve la URL de la foto de perfil si existe en disco
        private string? GetFotoUrl(int userId)
        {
            var dir = Path.Combine(_env.WebRootPath, "uploads", "avatars");
            if (!Directory.Exists(dir)) return null;
            var file = Directory.GetFiles(dir, $"{userId}.*").FirstOrDefault();
            return file != null ? "/uploads/avatars/" + Path.GetFileName(file) : null;
        }

        // GET /api/usuarios -- Solo Admin
        [Authorize(Roles = "Admin")]
        [HttpGet]
        public async Task<IActionResult> ObtenerUsuarios()
        {
            var usuarios = await _context.Usuarios
                .Select(u => new UsuarioResponseDto
                {
                    Id = u.Id,
                    Nombre = u.Nombre,
                    Apellido = u.Apellido,
                    Email = u.Email,
                    Telefono = u.Telefono,
                    Rol = u.Rol
                })
                .ToListAsync();

            return Ok(usuarios);
        }

        // GET /api/usuarios/perfil
        [HttpGet("perfil")]
        public async Task<IActionResult> MiPerfil()
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var usuario = await _context.Usuarios.FindAsync(userId);

            if (usuario == null)
                return NotFound();

            return Ok(new UsuarioResponseDto
            {
                Id            = usuario.Id,
                Nombre        = usuario.Nombre,
                Apellido      = usuario.Apellido,
                Email         = usuario.Email,
                Telefono      = usuario.Telefono,
                Rol           = usuario.Rol,
                FotoPerfilUrl = GetFotoUrl(usuario.Id),
                EmailConfirmado = usuario.EmailConfirmado
            });
        }

        // PUT /api/usuarios/perfil -- auto-edicion
        [HttpPut("perfil")]
        public async Task<IActionResult> ActualizarMiPerfil(ActualizarPerfilDto dto)
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var usuario = await _context.Usuarios.FindAsync(userId);

            if (usuario == null)
                return NotFound("Usuario no encontrado");

            if (!string.IsNullOrEmpty(dto.PasswordNueva))
            {
                if (string.IsNullOrEmpty(dto.PasswordActual))
                    return BadRequest("Debes ingresar tu contraseña actual para cambiarla.");

                if (!_passwordHelper.VerifyPassword(usuario, dto.PasswordActual, usuario.Password))
                    return BadRequest("La contraseña actual es incorrecta.");

                if (!EsPasswordValida(dto.PasswordNueva))
                    return BadRequest("La contraseña debe tener al menos una mayúscula, una minúscula, un número y un símbolo.");

                usuario.Password = _passwordHelper.HashPassword(usuario, dto.PasswordNueva);
            }

            usuario.Nombre   = dto.Nombre;
            usuario.Apellido = dto.Apellido;
            usuario.Telefono = dto.Telefono;

            await _context.SaveChangesAsync();

            return Ok(new UsuarioResponseDto
            {
                Id            = usuario.Id,
                Nombre        = usuario.Nombre,
                Apellido      = usuario.Apellido,
                Email         = usuario.Email,
                Telefono      = usuario.Telefono,
                Rol           = usuario.Rol,
                FotoPerfilUrl = GetFotoUrl(usuario.Id)
            });
        }

        // POST /api/usuarios/perfil/foto
        [HttpPost("perfil/foto")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> SubirFotoPerfil(IFormFile imagen)
        {
            if (imagen == null || imagen.Length == 0)
                return BadRequest("No se recibio ninguna imagen.");

            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var dir = Path.Combine(_env.WebRootPath, "uploads", "avatars");
            Directory.CreateDirectory(dir);

            // Eliminar foto anterior del mismo usuario
            foreach (var old in Directory.GetFiles(dir, $"{userId}.*"))
                System.IO.File.Delete(old);

            var ext = Path.GetExtension(imagen.FileName);
            var fileName = $"{userId}{ext}";
            var filePath = Path.Combine(dir, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
                await imagen.CopyToAsync(stream);

            return Ok(new { fotoPerfilUrl = $"/uploads/avatars/{fileName}" });
        }

        // POST /api/usuarios -- Solo Admin
        [Authorize(Roles = "Admin")]
        [HttpPost]
        public async Task<IActionResult> CrearUsuario(UsuarioCreateDto dto)
        {
            var existe = await _context.Usuarios.AnyAsync(u => u.Email == dto.Email);
            if (existe)
                return BadRequest("El email ya esta registrado.");

            var usuario = new Usuario
            {
                Nombre = dto.Nombre,
                Email = dto.Email,
                Rol = "Cliente"
            };

            usuario.Password = _passwordHelper.HashPassword(usuario, dto.Password);
            _context.Usuarios.Add(usuario);
            await _context.SaveChangesAsync();

            return Ok("Usuario creado correctamente.");
        }

        // PUT /api/usuarios/{id} -- Solo Admin
        [Authorize(Roles = "Admin")]
        [HttpPut("{id}")]
        public async Task<IActionResult> EditarUsuario(int id, UsuarioUpdateDto dto)
        {
            var usuario = await _context.Usuarios.FindAsync(id);

            if (usuario == null)
                return NotFound("Usuario no encontrado");

            usuario.Nombre   = dto.Nombre;
            usuario.Email    = dto.Email;
            usuario.Telefono = dto.Telefono;
            usuario.Apellido = dto.Apellido;

            if (!string.IsNullOrEmpty(dto.Password))
            {
                if (!EsPasswordValida(dto.Password))
                    return BadRequest("La contraseña debe tener al menos una mayúscula, una minúscula, un número y un símbolo.");
                usuario.Password = _passwordHelper.HashPassword(usuario, dto.Password);
            }

            await _context.SaveChangesAsync();
            return Ok("Usuario actualizado correctamente.");
        }

        // DELETE /api/usuarios/{id} -- Solo Admin
        [Authorize(Roles = "Admin")]
        [HttpDelete("{id}")]
        public async Task<IActionResult> EliminarUsuario(int id)
        {
            var usuario = await _context.Usuarios.FindAsync(id);

            if (usuario == null)
                return NotFound("Usuario no encontrado");

            _context.Usuarios.Remove(usuario);
            await _context.SaveChangesAsync();
            return Ok("Usuario eliminado correctamente.");
        }

        // PUT /api/usuarios/{id}/promover-admin -- Solo Admin
        [Authorize(Roles = "Admin")]
        [HttpPut("{id}/promover-admin")]
        public async Task<IActionResult> PromoverAAdmin(int id)
        {
            var usuario = await _context.Usuarios.FindAsync(id);

            if (usuario == null)
                return NotFound("Usuario no encontrado");

            if (usuario.Rol == "Admin")
                return BadRequest("El usuario ya es Admin");

            usuario.Rol = "Admin";
            await _context.SaveChangesAsync();
            return Ok($"El usuario {usuario.Email} ahora es Admin");
        }

        private static bool EsPasswordValida(string password) =>
            password.Any(char.IsUpper) &&
            password.Any(char.IsLower) &&
            password.Any(char.IsDigit) &&
            password.Any(c => !char.IsLetterOrDigit(c));
    }
}
