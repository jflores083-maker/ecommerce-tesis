using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class AddPerformanceIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Crear el índice compuesto ANTES de borrar el simple,
            // así MySQL tiene cobertura para la FK durante el drop.
            migrationBuilder.CreateIndex(
                name: "IX_ImagenesProducto_ProductoId_Orden",
                table: "ImagenesProducto",
                columns: new[] { "ProductoId", "Orden" });

            migrationBuilder.DropIndex(
                name: "IX_ImagenesProducto_ProductoId",
                table: "ImagenesProducto");

            migrationBuilder.CreateIndex(
                name: "IX_Productos_Activo_Categoria",
                table: "Productos",
                columns: new[] { "Activo", "Categoria" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Productos_Activo_Categoria",
                table: "Productos");

            migrationBuilder.DropIndex(
                name: "IX_ImagenesProducto_ProductoId_Orden",
                table: "ImagenesProducto");

            migrationBuilder.CreateIndex(
                name: "IX_ImagenesProducto_ProductoId",
                table: "ImagenesProducto",
                column: "ProductoId");
        }
    }
}
