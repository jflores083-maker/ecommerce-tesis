using Microsoft.EntityFrameworkCore;
using backend.Models;

namespace backend.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options)
        {
        }

        // Tablas
        public DbSet<Usuario> Usuarios { get; set; }
        public DbSet<Producto> Productos { get; set; }
        public DbSet<ImagenProducto> ImagenesProducto { get; set; }
        public DbSet<Carrito> Carritos { get; set; } = null!;
        public DbSet<ItemCarrito> ItemsCarrito { get; set; } = null!;
        public DbSet<Orden> Ordenes { get; set; } = null!;
        public DbSet<ItemOrden> ItemsOrden { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // =========================
            // Relaciones existentes
            // =========================

            // Usuario (vendedor) -> Productos (1:N)
            modelBuilder.Entity<Producto>()
                .HasOne(p => p.Vendedor)
                .WithMany() // si más adelante agregás nav inversa en Usuario, cámbialo por .WithMany(u => u.Productos)
                .HasForeignKey(p => p.VendedorId)
                .OnDelete(DeleteBehavior.Restrict);

            // Producto -> ImagenProducto (1:N)
            modelBuilder.Entity<ImagenProducto>()
                .HasOne(i => i.Producto)
                .WithMany(p => p.Imagenes) // <-- respeta tu propiedad "Imagenes" en Producto
                .HasForeignKey(i => i.ProductoId)
                .OnDelete(DeleteBehavior.Cascade);

            // =========================
            // Carrito e ItemCarrito
            // =========================
            
            modelBuilder.Entity<Carrito>().ToTable("Carritos");
            modelBuilder.Entity<ItemCarrito>().ToTable("ItemsCarrito");

            // Carrito 1:1 con Usuario (un carrito por usuario)
            modelBuilder.Entity<Carrito>()
                .HasIndex(c => c.UsuarioId)
                .IsUnique();

            modelBuilder.Entity<Carrito>()
                .HasOne(c => c.Usuario)
                .WithOne() // si en Usuario agregás "public Carrito Carrito {get;set;}" podés cambiar a .WithOne(u => u.Carrito)
                .HasForeignKey<Carrito>(c => c.UsuarioId)
                .OnDelete(DeleteBehavior.Cascade);

            // ItemCarrito N:1 Carrito
            modelBuilder.Entity<ItemCarrito>()
                .HasOne(i => i.Carrito)
                .WithMany(c => c.Items)
                .HasForeignKey(i => i.CarritoId)
                .OnDelete(DeleteBehavior.Cascade);

            // ItemCarrito N:1 Producto
            modelBuilder.Entity<ItemCarrito>()
                .HasOne(i => i.Producto)
                .WithMany() // no navegación inversa en Producto por ahora
                .HasForeignKey(i => i.ProductoId)
                .OnDelete(DeleteBehavior.Restrict);

            // Evitar duplicados (mismo Producto + Talle) dentro del mismo Carrito
            modelBuilder.Entity<ItemCarrito>()
                .HasIndex(i => new { i.CarritoId, i.ProductoId, i.Talle })
                .IsUnique();

            // Precisión decimal coherente con precios (MySQL DECIMAL(10,2))
            modelBuilder.Entity<ItemCarrito>()
                .Property(p => p.PrecioUnitarioSnapshot)
                .HasPrecision(10, 2);

            // Si no lo tenías ya en Producto, asegurate también de la precisión:
            modelBuilder.Entity<Producto>()
                .Property(p => p.Precio)
                .HasPrecision(10, 2);
            
            // ===== Órdenes e Items de Orden =====
            modelBuilder.Entity<Orden>().ToTable("Ordenes");
            modelBuilder.Entity<ItemOrden>().ToTable("ItemsOrden");

            modelBuilder.Entity<Orden>()
                .HasOne(o => o.Comprador)
                .WithMany() // si luego agregas nav inversa en Usuario, cámbialo
                .HasForeignKey(o => o.CompradorId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ItemOrden>()
                .HasOne(i => i.Orden)
                .WithMany(o => o.Items)
                .HasForeignKey(i => i.OrdenId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ItemOrden>()
                .HasOne(i => i.Producto)
                .WithMany()
                .HasForeignKey(i => i.ProductoId)
                .OnDelete(DeleteBehavior.Restrict);

            // Índices útiles
            modelBuilder.Entity<Orden>()
                .HasIndex(o => new { o.CompradorId, o.FechaCreacion });

            modelBuilder.Entity<ItemOrden>()
                .HasIndex(i => i.ProductoId);

            // Precisión decimal coherente con MySQL
            modelBuilder.Entity<Orden>()
                .Property(p => p.Subtotal)
                .HasPrecision(10, 2);
            modelBuilder.Entity<Orden>()
                .Property(p => p.CostoEnvio)
                .HasPrecision(10, 2);
            modelBuilder.Entity<Orden>()
                .Property(p => p.Total)
                .HasPrecision(10, 2);

            modelBuilder.Entity<ItemOrden>()
                .Property(p => p.PrecioUnitario)
                .HasPrecision(10, 2);
            modelBuilder.Entity<ItemOrden>()
                .Property(p => p.Subtotal)
                .HasPrecision(10, 2);
        }
    }
}