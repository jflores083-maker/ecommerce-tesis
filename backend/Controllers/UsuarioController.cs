using backend.Data;
using backend.Dtos;
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
    [Authorize] // requiere autenticación por defecto
    public class UsuarioController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly PasswordHelper _passwordHelper;

        public UsuarioController(AppDbContext context, PasswordHelper passwordHelper)
        {
            _context = context;
            _passwordHelper = passwordHelper;
        }

        // ===============================
        // 🔹 Obtener todos (Solo Admin)
        // ===============================
        [Authorize(Roles = "Admin")]
        [HttpGet]
        public async Task<IActionResult> ObtenerUsuarios()
        {
            var usuarios = await _context.Usuarios
                .Select(u => new UsuarioResponseDto
                {
                    Id = u.Id,
                    Nombre = u.Nombre,
                    Email = u.Email,
                    Rol = u.Rol
                })
                .ToListAsync();

            return Ok(usuarios);
        }

        // ===============================
        // 🔹 Obtener mi perfil
        // ===============================
        [HttpGet("perfil")]
        public async Task<IActionResult> MiPerfil()
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            var usuario = await _context.Usuarios.FindAsync(userId);

            if (usuario == null)
                return NotFound();

            return Ok(new UsuarioResponseDto
            {
                Id = usuario.Id,
                Nombre = usuario.Nombre,
                Email = usuario.Email,
                Rol = usuario.Rol
            });
        }

        // ===============================
        // 🔹 Crear usuario (Solo Admin)
        // ===============================
        [Authorize(Roles = "Admin")]
        [HttpPost]
        public async Task<IActionResult> CrearUsuario(UsuarioRegistroDto dto)
        {
            var existe = await _context.Usuarios.AnyAsync(u => u.Email == dto.Email);
            if (existe)
                return BadRequest("El email ya está registrado.");

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

        // ===============================
        // 🔹 Editar usuario (Solo Admin)
        // ===============================
        [Authorize(Roles = "Admin")]
        [HttpPut("{id}")]
        public async Task<IActionResult> EditarUsuario(int id, UsuarioRegistroDto dto)
        {
            var usuario = await _context.Usuarios.FindAsync(id);

            if (usuario == null)
                return NotFound("Usuario no encontrado");

            usuario.Nombre = dto.Nombre;
            usuario.Email = dto.Email;

            if (!string.IsNullOrEmpty(dto.Password))
            {
                usuario.Password = _passwordHelper.HashPassword(usuario, dto.Password);
            }

            await _context.SaveChangesAsync();

            return Ok("Usuario actualizado correctamente.");
        }

        // ===============================
        // 🔹 Eliminar usuario (Solo Admin)
        // ===============================
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

        // ===============================
        // 🔹 Promover a Admin (Solo Admin)
        // ===============================
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
    }
}
