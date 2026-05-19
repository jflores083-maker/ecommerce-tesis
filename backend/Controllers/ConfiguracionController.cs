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
        private string AcercaPath   => Path.Combine(_env.WebRootPath, "uploads", "acerca.json");
        private string ContactoPath => Path.Combine(_env.WebRootPath, "uploads", "contacto.json");
        private string EnvioPath       => Path.Combine(_env.WebRootPath, "uploads", "envio.json");
        private string CategoriasPath  => Path.Combine(_env.WebRootPath, "uploads", "categorias.json");

        public ConfiguracionController(IWebHostEnvironment env)
        {
            _env = env;
        }

        // GET /api/configuracion
        [HttpGet]
        [AllowAnonymous]
        public IActionResult Get()
        {
            // Hero
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
                acercaTitulo     = doc.GetProperty("titulo").GetString()      ?? acercaTitulo;
                acercaDescripcion = doc.GetProperty("descripcion").GetString() ?? "";
            }

            // Contacto
            string contactoEmail = ""; string contactoTelefono = "";
            string contactoDireccion = ""; string contactoHorario = "";
            if (System.IO.File.Exists(ContactoPath))
            {
                var cJson = System.IO.File.ReadAllText(ContactoPath);
                var cDoc = JsonDocument.Parse(cJson).RootElement;
                contactoEmail     = cDoc.GetProperty("email").GetString()     ?? "";
                contactoTelefono  = cDoc.GetProperty("telefono").GetString()  ?? "";
                contactoDireccion = cDoc.GetProperty("direccion").GetString() ?? "";
                contactoHorario   = cDoc.GetProperty("horario").GetString()   ?? "";
            }

            // Envío & devoluciones
            string envioTexto = "Envío gratis en compras mayores a $60.000. Entrega en 3-5 días hábiles.";
            if (System.IO.File.Exists(EnvioPath))
            {
                var eJson = System.IO.File.ReadAllText(EnvioPath);
                var eDoc  = JsonDocument.Parse(eJson).RootElement;
                envioTexto = eDoc.GetProperty("texto").GetString() ?? envioTexto;
            }

            // Categorías
            var defaultCategorias = new[] { "Remeras","Pantalones","Buzos","Abrigos","Accesorios","Calzado","Otros" };
            string[] categorias = defaultCategorias;
            if (System.IO.File.Exists(CategoriasPath))
            {
                var cJson = System.IO.File.ReadAllText(CategoriasPath);
                var cDoc  = JsonDocument.Parse(cJson).RootElement;
                categorias = cDoc.GetProperty("categorias").EnumerateArray()
                    .Select(e => e.GetString() ?? "")
                    .Where(s => s.Length > 0)
                    .ToArray();
            }

            return Ok(new {
                heroImageUrl = heroUrl,
                acercaTitulo, acercaDescripcion,
                contactoEmail, contactoTelefono, contactoDireccion, contactoHorario,
                envioTexto,
                categorias
            });
        }

        // POST /api/configuracion/hero
        [HttpPost("hero")]
        [Authorize(Roles = "Admin")]
        [Consumes("multipart/form-data")]
        public async Task<IActionResult> SubirHero(IFormFile imagen)
        {
            if (imagen == null || imagen.Length == 0)
                return BadRequest("No se recibio ninguna imagen.");

            var heroDir = Path.Combine(_env.WebRootPath, "uploads", "hero");
            Directory.CreateDirectory(heroDir);

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
                titulo      = doc.GetProperty("titulo").GetString()      ?? titulo;
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

        // GET /api/configuracion/categorias
        [HttpGet("categorias")]
        [AllowAnonymous]
        public IActionResult GetCategorias()
        {
            var defaults = new[] { "Remeras","Pantalones","Buzos","Abrigos","Accesorios","Calzado","Otros" };
            if (!System.IO.File.Exists(CategoriasPath))
                return Ok(new { categorias = defaults });

            var json = System.IO.File.ReadAllText(CategoriasPath);
            var doc  = JsonDocument.Parse(json).RootElement;
            var cats = doc.GetProperty("categorias").EnumerateArray()
                .Select(e => e.GetString() ?? "")
                .Where(s => s.Length > 0)
                .ToArray();
            return Ok(new { categorias = cats });
        }

        // PUT /api/configuracion/categorias
        [HttpPut("categorias")]
        [Authorize(Roles = "Admin")]
        public IActionResult GuardarCategorias([FromBody] CategoriasDto dto)
        {
            var cats = dto.Categorias.Where(c => !string.IsNullOrWhiteSpace(c)).Select(c => c.Trim()).ToList();
            Directory.CreateDirectory(Path.GetDirectoryName(CategoriasPath)!);
            var json = JsonSerializer.Serialize(new { categorias = cats });
            System.IO.File.WriteAllText(CategoriasPath, json);
            return Ok(new { categorias = cats });
        }

        // GET /api/configuracion/envio
        [HttpGet("envio")]
        [AllowAnonymous]
        public IActionResult GetEnvio()
        {
            string texto = "Envío gratis en compras mayores a $60.000. Entrega en 3-5 días hábiles.";
            if (System.IO.File.Exists(EnvioPath))
            {
                var json = System.IO.File.ReadAllText(EnvioPath);
                var doc  = JsonDocument.Parse(json).RootElement;
                texto    = doc.GetProperty("texto").GetString() ?? texto;
            }
            return Ok(new { texto });
        }

        // PUT /api/configuracion/envio
        [HttpPut("envio")]
        [Authorize(Roles = "Admin")]
        public IActionResult GuardarEnvio([FromBody] EnvioDto dto)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(EnvioPath)!);
            var json = JsonSerializer.Serialize(new { texto = dto.Texto });
            System.IO.File.WriteAllText(EnvioPath, json);
            return Ok(new { texto = dto.Texto });
        }

        // PUT /api/configuracion/contacto
        [HttpPut("contacto")]
        [Authorize(Roles = "Admin")]
        public IActionResult GuardarContacto([FromBody] ContactoDto dto)
        {
            Directory.CreateDirectory(Path.GetDirectoryName(ContactoPath)!);
            var json = JsonSerializer.Serialize(new {
                email     = dto.Email,
                telefono  = dto.Telefono,
                direccion = dto.Direccion,
                horario   = dto.Horario
            });
            System.IO.File.WriteAllText(ContactoPath, json);
            return Ok(dto);
        }
    }

    public class AcercaDto
    {
        public string Titulo      { get; set; } = string.Empty;
        public string Descripcion { get; set; } = string.Empty;
    }

    public class CategoriasDto
    {
        public List<string> Categorias { get; set; } = new();
    }

    public class EnvioDto
    {
        public string Texto { get; set; } = string.Empty;
    }

    public class ContactoDto
    {
        public string Email     { get; set; } = string.Empty;
        public string Telefono  { get; set; } = string.Empty;
        public string Direccion { get; set; } = string.Empty;
        public string Horario   { get; set; } = string.Empty;
    }
}
