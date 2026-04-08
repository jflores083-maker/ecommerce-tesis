using System.Net;
using System.Net.Mail;
using Microsoft.Extensions.Configuration;

namespace backend.Services
{
    public class EmailService
    {
        private readonly IConfiguration _config;

        public EmailService(IConfiguration config)
        {
            _config = config;
        }

        public async Task EnviarEmailAsync(string destinatario, string asunto, string cuerpoHtml)
        {
            var from = _config["Email:From"]!;
            var password = _config["Email:Password"]!;
            var host = _config["Email:Host"]!;
            var port = int.Parse(_config["Email:Port"]!);

            var smtpClient = new SmtpClient(host)
            {
                Port = port,
                Credentials = new NetworkCredential(from, password),
                EnableSsl = true
            };

            var mail = new MailMessage
            {
                From = new MailAddress(from, "Urbal Indumentaria"),
                Subject = asunto,
                Body = cuerpoHtml,
                IsBodyHtml = true
            };

            mail.To.Add(destinatario);

            await smtpClient.SendMailAsync(mail);
        }

        public string TemplateOrdenConfirmada(int ordenId, decimal total)
        {
            return $@"
                <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;'>
                    <h2 style='color: #333;'>¡Tu orden fue confirmada! 🎉</h2>
                    <p>Tu pago fue aprobado exitosamente.</p>
                    <div style='background: #f5f5f5; padding: 20px; border-radius: 8px;'>
                        <p><strong>Número de orden:</strong> #{ordenId}</p>
                        <p><strong>Total pagado:</strong> ${total:N2}</p>
                    </div>
                    <p>En breve recibirás información sobre el envío.</p>
                    <p>Gracias por comprar en <strong>Urbal Indumentaria Urbana</strong> 🛍️</p>
                </div>";
        }

        public string TemplateOrdenEnviada(int ordenId, string? numeroSeguimiento)
        {
            var seguimiento = string.IsNullOrEmpty(numeroSeguimiento)
                ? "Sin número de seguimiento"
                : numeroSeguimiento;

            return $@"
                <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;'>
                    <h2 style='color: #333;'>¡Tu orden fue enviada! 📦</h2>
                    <p>Tu pedido está en camino.</p>
                    <div style='background: #f5f5f5; padding: 20px; border-radius: 8px;'>
                        <p><strong>Número de orden:</strong> #{ordenId}</p>
                        <p><strong>Número de seguimiento:</strong> {seguimiento}</p>
                    </div>
                    <p>Gracias por comprar en <strong>Urbal Indumentaria Urbana</strong> 🛍️</p>
                </div>";
        }
    }
}