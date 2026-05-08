using backend.Controllers;
using backend.Data;
using backend.Dtos.Carrito;
using backend.Models;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using Xunit;

namespace backend.Tests
{
    public class CarritoTests
    {
        private AppDbContext CrearDbContext()
        {
            var options = new DbContextOptionsBuilder<AppDbContext>()
                .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
                .Options;
            return new AppDbContext(options);
        }

        private CarritoController CrearController(AppDbContext db, int userId = 1)
        {
            var controller = new CarritoController(db);
            var claims = new List<Claim>
            {
                new Claim(ClaimTypes.NameIdentifier, userId.ToString())
            };
            var identity = new ClaimsIdentity(claims);
            var principal = new ClaimsPrincipal(identity);
            controller.ControllerContext = new ControllerContext
            {
                HttpContext = new DefaultHttpContext { User = principal }
            };
            return controller;
        }

        private async Task<AppDbContext> SeedDatos(AppDbContext db, int stock = 10)
        {
            var usuario = new Usuario
            {
                Id = 1,
                Nombre = "Test",
                Apellido = "User",
                Email = "test@test.com",
                Password = "hash",
                Rol = "Cliente",
                EmailConfirmado = true
            };
            var producto = new Producto
            {
                Id = 1,
                VendedorId = 1,
                Titulo = "Remera Test",
                Descripcion = "Test",
                Precio = 1000,
                Stock = stock,
                Talles = "[\"S\",\"M\",\"L\"]",
                Categoria = "Remeras",
                Estado = "disponible",
                Activo = true,
                FechaPublicacion = DateTime.UtcNow
            };
            db.Usuarios.Add(usuario);
            db.Productos.Add(producto);
            await db.SaveChangesAsync();
            return db;
        }

        [Fact]
        public async Task AgregarItem_ConStockSuficiente_RetornaOk()
        {
            var db = await SeedDatos(CrearDbContext(), stock: 10);
            var controller = CrearController(db);
            var dto = new AgregarItemCarritoDto { ProductoId = 1, Talle = "M", Cantidad = 2 };

            var result = await controller.AgregarItem(dto);

            var ok = Assert.IsType<OkObjectResult>(result.Result);
            var carrito = Assert.IsType<CarritoDto>(ok.Value);
            Assert.Single(carrito.Items);
            Assert.Equal(2, carrito.Items[0].Cantidad);
        }

        [Fact]
        public async Task AgregarItem_SinStock_RetornaBadRequest()
        {
            var db = await SeedDatos(CrearDbContext(), stock: 0);
            var controller = CrearController(db);
            var dto = new AgregarItemCarritoDto { ProductoId = 1, Talle = "M", Cantidad = 1 };

            var result = await controller.AgregarItem(dto);

            Assert.IsType<BadRequestObjectResult>(result.Result);
        }

        [Fact]
        public async Task AgregarItem_CantidadSuperaStock_RetornaBadRequest()
        {
            var db = await SeedDatos(CrearDbContext(), stock: 3);
            var controller = CrearController(db);
            var dto = new AgregarItemCarritoDto { ProductoId = 1, Talle = "M", Cantidad = 5 };

            var result = await controller.AgregarItem(dto);

            Assert.IsType<BadRequestObjectResult>(result.Result);
        }

        [Fact]
        public async Task ActualizarCantidad_SuperaStock_RetornaBadRequest()
        {
            var db = await SeedDatos(CrearDbContext(), stock: 3);
            var controller = CrearController(db);

            var dtoAgregar = new AgregarItemCarritoDto { ProductoId = 1, Talle = "M", Cantidad = 1 };
            await controller.AgregarItem(dtoAgregar);

            var carrito = await db.Carritos.Include(c => c.Items).FirstAsync();
            var itemId = carrito.Items.First().Id;

            var dtoActualizar = new ActualizarItemCarritoDto { Cantidad = 5 };
            var result = await controller.ActualizarItem(itemId, dtoActualizar);

            Assert.IsType<BadRequestObjectResult>(result.Result);
        }

        [Fact]
        public async Task EliminarItem_ItemExistente_RetornaNoContent()
        {
            var db = await SeedDatos(CrearDbContext());
            var controller = CrearController(db);

            var dtoAgregar = new AgregarItemCarritoDto { ProductoId = 1, Talle = "M", Cantidad = 1 };
            await controller.AgregarItem(dtoAgregar);

            var carrito = await db.Carritos.Include(c => c.Items).FirstAsync();
            var itemId = carrito.Items.First().Id;

            var result = await controller.EliminarItem(itemId);

            Assert.IsType<NoContentResult>(result);
        }

        [Fact]
        public async Task VaciarCarrito_RetornaNoContent()
        {
            var db = await SeedDatos(CrearDbContext());
            var controller = CrearController(db);

            var dtoAgregar = new AgregarItemCarritoDto { ProductoId = 1, Talle = "M", Cantidad = 1 };
            await controller.AgregarItem(dtoAgregar);

            var result = await controller.VaciarCarrito();

            Assert.IsType<NoContentResult>(result);
        }
    }
}