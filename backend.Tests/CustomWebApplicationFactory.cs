using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using backend.Data;

namespace backend.Tests;

public class CustomWebApplicationFactory : WebApplicationFactory<Program>
{
    // Nombre fijo por instancia de factory — todos los scopes comparten la misma DB
    private readonly string _dbName = "TestDb_" + Guid.NewGuid();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        builder.ConfigureServices(services =>
        {
            // En modo Testing, Program.cs no registra MySQL.
            // Registramos InMemory con nombre fijo para esta instancia.
            services.AddDbContext<AppDbContext>(options =>
                options.UseInMemoryDatabase(_dbName));
        });
    }
}
