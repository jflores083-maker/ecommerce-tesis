using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using backend.Data;

namespace backend.Tests;

public class CustomWebApplicationFactory : WebApplicationFactory<Program>
{
    private readonly string _dbName = "TestDb_" + Guid.NewGuid();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        builder.ConfigureAppConfiguration((context, config) =>
        {
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Email:Host"] = "localhost",
                ["Email:Port"] = "25",
                ["Email:From"] = "test@test.com",
                ["Email:Password"] = "test",
                ["MercadoPago:AccessToken"] = "TEST-token",
                ["MercadoPago:IsSandbox"] = "true",
                ["MercadoPago:WebhookSecret"] = "test-secret",
                ["Jwt:Key"] = "test-key-super-secreta-para-tests-1234567890",
                ["Jwt:Issuer"] = "test",
                ["Jwt:Audience"] = "test"
            });
        });

        builder.ConfigureServices(services =>
        {
            services.AddDbContext<AppDbContext>(options =>
                options.UseInMemoryDatabase(_dbName));
        });
    }
}