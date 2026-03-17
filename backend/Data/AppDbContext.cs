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
        public DbSet<Drop> Drops { get; set; } = null!;
        public DbSet<DropProducto> DropProductos { get; set; } = null!;

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Usuario (vendedor) -> Productos (1:N)
            modelBuilder.Entity<Producto>()
                .HasOne(p => p.Vendedor)
                .WithMany()
                .HasForeignKey(p => p.VendedorId)
                .OnDelete(DeleteBehavior.Restrict);

            // Producto -> ImagenProducto (1:N)
            modelBuilder.Entity<ImagenProducto>()
                .HasOne(i => i.Producto)
                .WithMany(p => p.Imagenes)
                .HasForeignKey(i => i.ProductoId)
                .OnDelete(DeleteBehavior.Cascade);

            // Carrito
            modelBuilder.Entity<Carrito>().ToTable("Carritos");
            modelBuilder.Entity<ItemCarrito>().ToTable("ItemsCarrito");

            modelBuilder.Entity<Carrito>()
                .HasIndex(c => c.UsuarioId)
                .IsUnique();

            modelBuilder.Entity<Carrito>()
                .HasOne(c => c.Usuario)
                .WithOne()
                .HasForeignKey<Carrito>(c => c.UsuarioId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ItemCarrito>()
                .HasOne(i => i.Carrito)
                .WithMany(c => c.Items)
                .HasForeignKey(i => i.CarritoId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<ItemCarrito>()
                .HasOne(i => i.Producto)
                .WithMany()
                .HasForeignKey(i => i.ProductoId)
                .OnDelete(DeleteBehavior.Restrict);

            modelBuilder.Entity<ItemCarrito>()
                .HasIndex(i => new { i.CarritoId, i.ProductoId, i.Talle })
                .IsUnique();

            modelBuilder.Entity<ItemCarrito>()
                .Property(p => p.PrecioUnitarioSnapshot)
                .HasPrecision(10, 2);

            modelBuilder.Entity<Producto>()
                .Property(p => p.Precio)
                .HasPrecision(10, 2);

            // Ordenes
            modelBuilder.Entity<Orden>().ToTable("Ordenes");
            modelBuilder.Entity<ItemOrden>().ToTable("ItemsOrden");

            modelBuilder.Entity<Orden>()
                .HasOne(o => o.Comprador)
                .WithMany()
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

            modelBuilder.Entity<Orden>()
                .HasIndex(o => new { o.CompradorId, o.FechaCreacion });

            modelBuilder.Entity<ItemOrden>()
                .HasIndex(i => i.ProductoId);

            modelBuilder.Entity<Orden>()
                .Property(p => p.Subtotal).HasPrecision(10, 2);
            modelBuilder.Entity<Orden>()
                .Property(p => p.CostoEnvio).HasPrecision(10, 2);
            modelBuilder.Entity<Orden>()
                .Property(p => p.Total).HasPrecision(10, 2);

            modelBuilder.Entity<ItemOrden>()
                .Property(p => p.PrecioUnitario).HasPrecision(10, 2);
            modelBuilder.Entity<ItemOrden>()
                .Property(p => p.Subtotal).HasPrecision(10, 2);

            // Índices de rendimiento
            modelBuilder.Entity<Producto>()
                .HasIndex(p => p.VendedorId);

            modelBuilder.Entity<Producto>()
                .HasIndex(p => new { p.Activo, p.Categoria });

            modelBuilder.Entity<ImagenProducto>()
                .HasIndex(i => new { i.ProductoId, i.Orden });

            modelBuilder.Entity<DropProducto>()
                .HasIndex(dp => dp.ProductoId);

            // Drops
            modelBuilder.Entity<Drop>().ToTable("Drops");
            modelBuilder.Entity<DropProducto>().ToTable("DropProductos");

            modelBuilder.Entity<DropProducto>()
                .HasKey(dp => new { dp.DropId, dp.ProductoId });

            modelBuilder.Entity<DropProducto>()
                .HasOne(dp => dp.Drop)
                .WithMany(d => d.DropProductos)
                .HasForeignKey(dp => dp.DropId)
                .OnDelete(DeleteBehavior.Cascade);

            modelBuilder.Entity<DropProducto>()
                .HasOne(dp => dp.Producto)
                .WithMany()
                .HasForeignKey(dp => dp.ProductoId)
                .OnDelete(DeleteBehavior.Restrict);
        }
    }
}
