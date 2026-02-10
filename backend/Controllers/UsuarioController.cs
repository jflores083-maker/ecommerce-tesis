using backend.Data;
using backend.Dtos;
using backend.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using backend.Helpers;
using Microsoft.AspNetCore.Authorization;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/usuarios")]
    public class UsuarioController : ControllerBase
    {
        private readonly AppDbContext _context;

        public UsuarioController(AppDbContext context)
        {
            _context = context;
        }

        // POST: api/usuarios/registro
        [HttpPost("registro")]
        public async Task<IActionResult> Registrar(UsuarioRegistroDto dto)
        {
            // verificar si ya existe
            var existe = await _context.Usuarios.AnyAsync(u => u.Email == dto.Email);
            if (existe)
                return BadRequest("El email ya está registrado.");

            var usuario = new Usuario
            {
                Nombre = dto.Nombre,
                Email = dto.Email,
                Password = dto.Password,  // texto plano por ahora
                Rol = "Cliente"
            };

            _context.Usuarios.Add(usuario);
            await _context.SaveChangesAsync();

            return Ok("Usuario registrado correctamente.");
        }


        // POST: api/usuarios/login
        [HttpPost("login")]
public async Task<IActionResult> Login(UsuarioLoginDto dto, [FromServices] JwtHelper jwt)
{
    var usuario = await _context.Usuarios
        .FirstOrDefaultAsync(u => u.Email == dto.Email && u.Password == dto.Password);

    if (usuario == null)
        return Unauthorized("Credenciales incorrectas.");

    var token = jwt.GenerarToken(usuario);

    return Ok(new
    {
        mensaje = "Login exitoso",
        token = token
    });
}
[Authorize]
[HttpGet("perfil")]
public IActionResult Perfil()
{
    return Ok("Usuario autenticado.");
}
[Authorize(Roles = "Admin")]
[HttpPost("crear")]
public IActionResult CrearAlgo()
{
    return Ok("Solo Admin puede entrar acá");
}
[Authorize(Roles = "Cliente")]
[HttpGet("solo-cliente")]
public IActionResult ClienteEndpoint()
{
    return Ok("Solo clientes pueden entrar");
}
[AllowAnonymous]
[HttpGet("publico")]
public IActionResult Publico()
{
    return Ok("Cualquiera puede verlo");
}

[Authorize(Roles = "Admin")]
[HttpGet("admin/prueba")]
public IActionResult PruebaAdmin()
{
    return Ok("Acceso permitido: sos admin.");
}



    }
}
