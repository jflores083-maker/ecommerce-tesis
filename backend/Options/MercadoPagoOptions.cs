namespace backend.Options
{
    public class MercadoPagoOptions
    {
        public string AccessToken { get; set; } = null!;
        public bool IsSandbox { get; set; }
    }
}