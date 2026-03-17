using System.Net;
using System.Net.Http.Json;
using Microsoft.Extensions.DependencyInjection;
using backend.Data;
using backend.Models;

namespace backend.Tests;

public class DropsControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly CustomWebApplicationFactory _factory;

    public DropsControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    // ── GET /api/drops ────────────────────────────────────────────────────────

    [Fact]
    public async Task GetDrops_CuandoNoHayDrops_RetornaListaVacia()
    {
        var response = await _client.GetAsync("/api/drops");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var lista = await response.Content.ReadFromJsonAsync<List<object>>();
        Assert.NotNull(lista);
        Assert.Empty(lista);
    }

    [Fact]
    public async Task GetDrops_CuandoHayDrops_RetornaListaConItems()
    {
        // Arrange: seed de un drop directamente en la DB
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        db.Drops.Add(new Drop { Nombre = "Drop Verano", FechaCreacion = DateTime.UtcNow });
        await db.SaveChangesAsync();

        // Act
        var response = await _client.GetAsync("/api/drops");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var lista = await response.Content.ReadFromJsonAsync<List<System.Text.Json.JsonElement>>();
        Assert.NotNull(lista);
        Assert.True(lista.Count >= 1);
        Assert.Contains(lista, d => d.GetProperty("nombre").GetString() == "Drop Verano");
    }

    // ── GET /api/drops/{id} ───────────────────────────────────────────────────

    [Fact]
    public async Task GetDrop_CuandoNoExiste_Retorna404()
    {
        var response = await _client.GetAsync("/api/drops/99999");
        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task GetDrop_CuandoExiste_RetornaDatosCorrectos()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var drop = new Drop { Nombre = "Drop Invierno", FechaCreacion = DateTime.UtcNow };
        db.Drops.Add(drop);
        await db.SaveChangesAsync();

        // Act
        var response = await _client.GetAsync($"/api/drops/{drop.Id}");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        Assert.Equal("Drop Invierno", body.GetProperty("nombre").GetString());
        Assert.Equal(0, body.GetProperty("productos").GetArrayLength());
    }

    // ── GET /api/drops/por-producto/{productoId} ─────────────────────────────

    [Fact]
    public async Task GetDropsPorProducto_CuandoProductoNoEstaEnNingunDrop_RetornaListaVacia()
    {
        var response = await _client.GetAsync("/api/drops/por-producto/99999");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var ids = await response.Content.ReadFromJsonAsync<List<int>>();
        Assert.NotNull(ids);
        Assert.Empty(ids);
    }

    [Fact]
    public async Task GetDropsPorProducto_CuandoProductoEstaEnUnDrop_RetornaIdDelDrop()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        var vendedor = new Usuario
        {
            Nombre = "Test", Email = $"t_{Guid.NewGuid()}@t.com",
            Password = "x", Rol = "Admin"
        };
        db.Usuarios.Add(vendedor);
        await db.SaveChangesAsync();

        var producto = new Producto
        {
            Titulo = "Remera", Precio = 100, Estado = "disponible",
            VendedorId = vendedor.Id
        };
        db.Productos.Add(producto);

        var drop = new Drop { Nombre = "Drop Test", FechaCreacion = DateTime.UtcNow };
        db.Drops.Add(drop);
        await db.SaveChangesAsync();

        db.DropProductos.Add(new DropProducto { DropId = drop.Id, ProductoId = producto.Id });
        await db.SaveChangesAsync();

        // Act
        var response = await _client.GetAsync($"/api/drops/por-producto/{producto.Id}");

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var ids = await response.Content.ReadFromJsonAsync<List<int>>();
        Assert.NotNull(ids);
        Assert.Contains(drop.Id, ids);
    }

    // ── POST /api/drops — sin auth ────────────────────────────────────────────

    [Fact]
    public async Task CrearDrop_SinAutenticacion_Retorna401()
    {
        var form = new MultipartFormDataContent();
        form.Add(new StringContent("Drop Sin Auth"), "nombre");

        var response = await _client.PostAsync("/api/drops", form);

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    // ── DELETE /api/drops/{id} — sin auth ─────────────────────────────────────

    [Fact]
    public async Task EliminarDrop_SinAutenticacion_Retorna401()
    {
        var response = await _client.DeleteAsync("/api/drops/1");
        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
