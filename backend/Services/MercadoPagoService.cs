using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using backend.Options;
using Microsoft.Extensions.Options;

namespace backend.Services
{
    public class MercadoPagoService
    {
        private readonly HttpClient _httpClient;
        private readonly MercadoPagoOptions _options;

        public MercadoPagoService(
            IOptions<MercadoPagoOptions> options)
        {
            _options = options.Value;

            _httpClient = new HttpClient
            {
                BaseAddress = new Uri("https://api.mercadopago.com/")
            };

            _httpClient.DefaultRequestHeaders.Authorization =
                new AuthenticationHeaderValue("Bearer", _options.AccessToken);
        }

        public async Task<string> CrearPreferenciaAsync(
            int ordenId,
            decimal monto,
            string descripcion)
        {
            var payload = new
            {
                items = new[]
                {
                    new
                    {
                        title = descripcion,
                        quantity = 1,
                        currency_id = "ARS",
                        unit_price = monto
                    }
                },
                external_reference = ordenId.ToString(),

                notification_url = "https://petrina-unprofited-darrin.ngrok-free.dev/api/pagos/webhook", //nuevo agregado

                back_urls = new
                {
                    //success = "https://www.mercadopago.com.ar",
                    //failure = "https://www.mercadopago.com.ar",
                    //pending = "https://www.mercadopago.com.ar"

                    success = "https://petrina-unprofited-darrin.ngrok-free.dev",
                    failure = "https://petrina-unprofited-darrin.ngrok-free.dev",
                    pending = "https://petrina-unprofited-darrin.ngrok-free.dev",
                },

                auto_return = "approved"
            };

            var json = JsonSerializer.Serialize(payload);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await _httpClient
                .PostAsync("checkout/preferences", content);

            response.EnsureSuccessStatusCode();

            var responseJson = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(responseJson);

            var property = _options.IsSandbox ? "sandbox_init_point" : "init_point";
            return doc.RootElement
                .GetProperty(property)
                .GetString()!;
                }
                public async Task<JsonElement> ObtenerPagoAsync(string paymentId)
        {
            var response = await _httpClient.GetAsync($"v1/payments/{paymentId}");
            response.EnsureSuccessStatusCode();

            var responseJson = await response.Content.ReadAsStringAsync();
            using var doc = JsonDocument.Parse(responseJson);

            return doc.RootElement.Clone();
        }
    }
    
}