using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace backend.Dtos.Productos
{
    public class AjustarPreciosDto
    {
        [Required]
        public List<int> ProductoIds { get; set; } = new();

        /// Porcentaje a aplicar. Positivo = aumento, negativo = rebaja.
        /// Ej: 15 = +15%, -10 = -10%
        [Required, Range(-99, 1000)]
        public decimal Porcentaje { get; set; }
    }
}
