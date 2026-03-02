using System;
using System.Collections.Generic;

namespace backend.Models
{
    public class Carrito
    {
        public int Id { get; set; }
        public int UsuarioId { get; set; } // 1:1 con Usuario
        public DateTime FechaCreacion { get; set; } = DateTime.UtcNow;
        public DateTime FechaActualizacion { get; set; } = DateTime.UtcNow;

        public Usuario Usuario { get; set; } = null!;
        public ICollection<ItemCarrito> Items { get; set; } = new List<ItemCarrito>();
    }
}