using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace backend.Controllers
{
    [ApiController]
    [Route("api/configuracion")]
    public class ConfiguracionController : ControllerBase
    {
        private readonly IWebHostEnvironment _env;

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

            return Ok(new { heroImageUrl = heroUrl });
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
    }
}
