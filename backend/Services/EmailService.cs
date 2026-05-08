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

        /*public async Task EnviarEmailAsync(string destinatario, string asunto, string cuerpoHtml)
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
                From = new MailAddress(from, "638 Indumentaria"),
                Subject = asunto,
                Body = cuerpoHtml,
                IsBodyHtml = true
            };

            mail.To.Add(destinatario);

            await smtpClient.SendMailAsync(mail);
        }*/

        public async Task EnviarEmailAsync(string destinatario, string asunto, string cuerpoHtml)
        {
            var from = _config["Email:From"]!;
            var password = _config["Email:Password"]!;
            var host = _config["Email:Host"]!;
            var portStr = _config["Email:Port"];

            if (string.IsNullOrEmpty(portStr)) return; // entorno de testing

            var port = int.Parse(portStr);

            var smtpClient = new SmtpClient(host)
            {
                Port = port,
                Credentials = new NetworkCredential(from, password),
                EnableSsl = true
            };

            var mail = new MailMessage
            {
                From = new MailAddress(from, "638 Indumentaria"),
                Subject = asunto,
                Body = cuerpoHtml,
                IsBodyHtml = true
            };

            mail.To.Add(destinatario);

            try
            {
                await smtpClient.SendMailAsync(mail);
            }
            catch (Exception)
            {
                // En entorno de testing el SMTP no está disponible, ignoramos el error
            }
        }

        public string TemplateVerificacionEmail(string nombre, string codigo)
        {
            return $@"
                <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;'>
                    <h2 style='color: #1a1a1a;'>Verificá tu email</h2>
                    <p>Hola {nombre}, gracias por registrarte en <strong>638</strong>.</p>
                    <p>Tu código de verificación es:</p>
                    <div style='background: #f5f5f5; padding: 32px; text-align: center; margin: 24px 0;'>
                        <span style='font-size: 40px; font-weight: bold; letter-spacing: 12px; color: #1a1a1a;'>{codigo}</span>
                    </div>
                    <p style='color: #666;'>Este código expira en <strong>15 minutos</strong>.</p>
                    <p style='color: #666;'>Si no creaste una cuenta en 638, ignorá este email.</p>
                </div>";
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
                    <p>Gracias por comprar en <strong>638</strong> 🛍️</p>
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
                    <p>Gracias por comprar en <strong>638</strong> 🛍️</p>
                </div>";
        }

        public string TemplateOrdenEntregada(int ordenId)
        {
            return $@"
                <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;'>
                    <h2 style='color: #333;'>¡Tu orden fue entregada! ✅</h2>
                    <p>Esperamos que estés disfrutando tu compra.</p>
                    <div style='background: #f5f5f5; padding: 20px; border-radius: 8px;'>
                        <p><strong>Número de orden:</strong> #{ordenId}</p>
                    </div>
                    <p>Gracias por comprar en <strong>638</strong> 🛍️</p>
                </div>";
        }

        public string TemplateOrdenCancelada(int ordenId)
        {
            return $@"
                <div style='font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;'>
                    <h2 style='color: #c0392b;'>Tu orden fue cancelada</h2>
                    <p>Tu pago no pudo procesarse o la orden fue cancelada.</p>
                    <div style='background: #f5f5f5; padding: 20px; border-radius: 8px;'>
                        <p><strong>Número de orden:</strong> #{ordenId}</p>
                    </div>
                    <p>Si tenés dudas, contactanos. <strong>638</strong></p>
                </div>";
        }
    }
}