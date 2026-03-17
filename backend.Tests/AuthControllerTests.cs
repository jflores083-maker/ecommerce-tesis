using System.Net;
using System.Net.Http.Json;
using Microsoft.Extensions.DependencyInjection;
using backend.Data;
using backend.Models;

namespace backend.Tests;

public class AuthControllerTests : IClassFixture<CustomWebApplicationFactory>
{
    private readonly HttpClient _client;
    private readonly CustomWebApplicationFactory _factory;

    public AuthControllerTests(CustomWebApplicationFactory factory)
    {
        _factory = factory;
        _client = factory.CreateClient();
    }

    // Helper: payload válido para registro
    private static object RegistroPayload(string email, string password = "Password123!") => new
    {
        nombre = "Juan",
        apellido = "Test",
        email,
        telefono = "+5491112345678",
        password
    };

    // ── POST /api/auth/register ───────────────────────────────────────────────

    [Fact]
    public async Task Registrar_ConDatosValidos_Retorna200()
    {
        var payload = RegistroPayload($"juan_{Guid.NewGuid()}@test.com");

        var response = await _client.PostAsJsonAsync("/api/auth/register", payload);

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [Fact]
    public async Task Registrar_ConEmailDuplicado_Retorna400()
    {
        var email = $"dup_{Guid.NewGuid()}@test.com";
        var payload = RegistroPayload(email);

        await _client.PostAsJsonAsync("/api/auth/register", payload);
        var response = await _client.PostAsJsonAsync("/api/auth/register", payload);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Registrar_SinCamposObligatorios_Retorna400()
    {
        var payload = new { nombre = "Solo nombre" };

        var response = await _client.PostAsJsonAsync("/api/auth/register", payload);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    // ── POST /api/auth/login ──────────────────────────────────────────────────

    [Fact]
    public async Task Login_ConCredencialesCorrectas_Retorna200ConToken()
    {
        // Arrange: registrar primero
        var email = $"login_{Guid.NewGuid()}@test.com";
        var password = "TestPass456!";
        await _client.PostAsJsonAsync("/api/auth/register", RegistroPayload(email, password));

        // Act
        var response = await _client.PostAsJsonAsync("/api/auth/login",
            new { email, password });

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<System.Text.Json.JsonElement>();
        Assert.True(body.TryGetProperty("token", out var token));
        Assert.False(string.IsNullOrEmpty(token.GetString()));
    }

    [Fact]
    public async Task Login_ConPasswordIncorrecta_Retorna401()
    {
        var email = $"wrong_{Guid.NewGuid()}@test.com";
        await _client.PostAsJsonAsync("/api/auth/register", RegistroPayload(email, "CorrectPass123!"));

        var response = await _client.PostAsJsonAsync("/api/auth/login",
            new { email, password = "WrongPassword!" });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Login_ConEmailInexistente_Retorna401()
    {
        var response = await _client.PostAsJsonAsync("/api/auth/login",
            new { email = "noexiste@test.com", password = "cualquier" });

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }
}
