using System.Net;
using System.Net.Http.Json;
using Microsoft.Extensions.DependencyInjection;
using backend.Data;
using backend.Models;

namespace backend.Tests;

public class ProductosControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly CustomWebApplicationFactory _factory;

    public ProductosControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    // ── GET /api/productos ────────────────────────────────────────────────────

    [Fact]
    public async Task GetProductos_RetornaOk()
    {
        var response = await _client.GetAsync("/api/productos");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task GetProductos_CuandoHayProductos_LosIncluye()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var vendedor = new Usuario
        {
            Nombre = "Vendedor", Email = $"v_{Guid.NewGuid()}@t.com",
            Password = "x", Rol = "Admin"
        };
        db.Usuarios.Add(vendedor);
        await db.SaveChangesAsync();

        db.Productos.Add(new Producto
        {
            Titulo = "Campera Negra", Precio = 5000, Estado = "disponible",
            VendedorId = vendedor.Id
        });
        await db.SaveChangesAsync();

        // Act
        var response = await _client.GetAsync("/api/productos");
        var lista = await response.Content.ReadFromJsonAsync<List<System.Text.Json.JsonElement>>();

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.NotNull(lista);
        Assert.Contains(lista, p => p.GetProperty("titulo").GetString() == "Campera Negra");
    }

    // ── GET /api/productos/{id} ───────────────────────────────────────────────

    [Fact]
    public async Task GetProducto_CuandoNoExiste_Retorna404()
    {
        var response = await _client.GetAsync("/api/productos/99999");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetProducto_CuandoExiste_RetornaDatosCorrectos()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var vendedor = new Usuario
        {
            Nombre = "V2", Email = $"v2_{Guid.NewGuid()}@t.com",
            Password = "x", Rol = "Admin"
        };
        db.Usuarios.Add(vendedor);
        await db.SaveChangesAsync();

        var producto = new Producto
        {
            Titulo = "Jean Slim", Precio = 3500, Estado = "disponible",
            VendedorId = vendedor.Id
        };
        db.Productos.Add(producto);
        await db.SaveChangesAsync();

        // Act
        var response = await _client.GetAsync($"/api/productos/{producto.Id}");
        var body = await response.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("Jean Slim", body.GetProperty("titulo").GetString());
        Assert.Equal(3500, body.GetProperty("precio").GetDecimal());
    }

    // ── POST /api/productos — sin auth ────────────────────────────────────────

    [Fact]
    public async Task CrearProducto_SinAutenticacion_Retorna401()
    {
        var form = new MultipartFormDataContent();
        form.Add(new StringContent("Producto Test"), "titulo");
        form.Add(new StringContent("1000"), "precio");

        var response = await _client.PostAsync("/api/productos", form);
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
