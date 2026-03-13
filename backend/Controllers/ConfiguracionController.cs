using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/configuracion")]
    public class ConfiguracionController : ControllerBase
    {
        private readonly IWebHostEnvironment _env;
        private string AcercaPath => Path.Combine(_env.WebRootPath, "uploads", "acerca.json");

        public ConfiguracionController(IWebHostEnvironment env)
        {
            _env = env;
        }

        // GET /api/configuracion
        [HttpGet]
        [AllowAnonymous]
        public IActionResult Get()
        {
            var heroDir = Path.Combine(_env.WebRootPath, "uploads", "hero");
            string? heroUrl = null;

            if (Directory.Exists(heroDir))
            {
                var file = Directory.GetFiles(heroDir).FirstOrDefault();
                if (file != null)
                    heroUrl = "/uploads/hero/" + Path.GetFileName(file);
            }

            // Acerca de
            string acercaTitulo = "Sobre 638";
            string acercaDescripcion = "";
            if (System.IO.File.Exists(AcercaPath))
            {
                var json = System.IO.File.ReadAllText(AcercaPath);
                var doc = JsonDocument.Parse(json).RootElement;
                acercaTitulo = doc.GetProperty("titulo").GetString() ?? acercaTitulo;
                acercaDescripcion = doc.GetProperty("descripcion").GetString() ?? "";
            }

            return Ok(new { heroImageUrl = heroUrl, acercaTitulo, acercaDescripcion });
        }

        // POST /api/configuracion/hero
        [HttpPost("hero")]
        [Authorize(Roles = "Admin")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> SubirHero(IFormFile imagen)
        {
            if (imagen == null || imagen.Length == 0)
                return BadRequest("No se recibió ninguna imagen.");

            var heroDir = Path.Combine(_env.WebRootPath, "uploads", "hero");
            Directory.CreateDirectory(heroDir);

            // Eliminar imagen anterior
            foreach (var old in Directory.GetFiles(heroDir))
                System.IO.File.Delete(old);

            var ext = Path.GetExtension(imagen.FileName);
            var fileName = $"hero{ext}";
            var filePath = Path.Combine(heroDir, fileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
                await imagen.CopyToAsync(stream);

            return Ok(new { heroImageUrl = $"/uploads/hero/{fileName}" });
        }

        // GET /api/configuracion/acerca
        [HttpGet("acerca")]
        [AllowAnonymous]
        public IActionResult GetAcerca()
        {
            string titulo = "Sobre 638";
            string descripcion = "";
            if (System.IO.File.Exists(AcercaPath))
            {
                var json = System.IO.File.ReadAllText(AcercaPath);
                var doc = JsonDocument.Parse(json).RootElement;
                titulo = doc.GetProperty("titulo").GetString() ?? titulo;
                descripcion = doc.GetProperty("descripcion").GetString() ?? "";
            }
            return Ok(new { titulo, descripcion });
        }

        // PUT /api/configuracion/acerca
        [HttpPut("acerca")]
        [Authorize(Roles = "Admin")]
        public IActionResult GuardarAcerca([FromBody] AcercaDto dto)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(AcercaPath)!);
            var json = JsonSerializer.Serialize(new { titulo = dto.Titulo, descripcion = dto.Descripcion });
            System.IO.File.WriteAllText(AcercaPath, json);
            return Ok(new { titulo = dto.Titulo, descripcion = dto.Descripcion });
        }
    }

    public class AcercaDto
    {
        public string Titulo { get; set; } = string.Empty;
        public string Descripcion { get; set; } = string.Empty;
    }
}
