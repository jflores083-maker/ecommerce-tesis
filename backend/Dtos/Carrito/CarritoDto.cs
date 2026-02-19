using System.Collections.Generic;
using System.Linq;

namespace backend.Dtos.Carrito
{
    public class CarritoDto
    {
        public int CarritoId { get; set; }
        public List<ItemCarritoDto> Items { get; set; } = new();
        public decimal Subtotal => Items.Sum(i => i.Subtotal);
    }
}