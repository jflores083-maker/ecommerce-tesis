import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_638/providers/carrito_provider.dart';
import 'package:app_638/models/models.dart';
import 'package:app_638/services/api_service.dart';
import 'mocks.dart';

void main() {
  late MockApiService api;
  late CarritoProvider provider;

  setUp(() {
    api = MockApiService();
    provider = CarritoProvider(api);
  });

  Carrito carritoVacio() => Carrito(carritoId: 1, items: []);

  Carrito carritoConItem() => Carrito(
    carritoId: 1,
    items: [
      ItemCarrito(
        id: 10,
        productoId: 5,
        titulo: 'Remera',
        talle: 'M',
        cantidad: 1,
        precioUnitarioVigente: 1500,
      ),
    ],
  );

  // ── estado inicial ────────────────────────────────────────────────────────

  test('estado inicial: carrito nulo, sin carga, sin error', () {
    expect(provider.carrito, isNull);
    expect(provider.loading, false);
    expect(provider.error, isNull);
    expect(provider.totalItems, 0);
    expect(provider.subtotal, 0);
  });

  // ── cargarCarrito ─────────────────────────────────────────────────────────

  group('cargarCarrito', () {
    test('cuando la API retorna carrito, lo almacena', () async {
      when(() => api.getCarrito()).thenAnswer((_) async => carritoVacio());

      await provider.cargarCarrito();

      expect(provider.carrito, isNotNull);
      expect(provider.loading, false);
      expect(provider.error, isNull);
    });

    test('cuando la API lanza ApiException, guarda el mensaje de error', () async {
      when(() => api.getCarrito())
          .thenThrow(ApiException(statusCode: 500, message: 'Sin conexión'));

      await provider.cargarCarrito();

      expect(provider.error, 'Sin conexión');
      expect(provider.loading, false);
    });
  });

  // ── agregar ───────────────────────────────────────────────────────────────

  group('agregar', () {
    test('en éxito, actualiza el carrito y retorna true', () async {
      when(() => api.agregarItem(
        productoId: any(named: 'productoId'),
        talle: any(named: 'talle'),
        cantidad: any(named: 'cantidad'),
      )).thenAnswer((_) async => carritoConItem());

      final ok = await provider.agregar(productoId: 5, talle: 'M');

      expect(ok, true);
      expect(provider.totalItems, 1);
      expect(provider.items.first.titulo, 'Remera');
      expect(provider.error, isNull);
    });

    test('cuando la API falla, guarda el error y retorna false', () async {
      when(() => api.agregarItem(
        productoId: any(named: 'productoId'),
        talle: any(named: 'talle'),
        cantidad: any(named: 'cantidad'),
      )).thenThrow(ApiException(statusCode: 400, message: 'Stock insuficiente'));

      final ok = await provider.agregar(productoId: 5, talle: 'M');

      expect(ok, false);
      expect(provider.error, 'Stock insuficiente');
    });
  });

  // ── limpiarLocal ──────────────────────────────────────────────────────────

  test('limpiarLocal deja el carrito en null', () async {
    when(() => api.getCarrito()).thenAnswer((_) async => carritoVacio());
    await provider.cargarCarrito();
    expect(provider.carrito, isNotNull);

    provider.limpiarLocal();

    expect(provider.carrito, isNull);
  });

  // ── clearError ────────────────────────────────────────────────────────────

  test('clearError limpia el mensaje de error', () async {
    when(() => api.getCarrito())
        .thenThrow(ApiException(statusCode: 500, message: 'Error'));
    await provider.cargarCarrito();
    expect(provider.error, isNotNull);

    provider.clearError();

    expect(provider.error, isNull);
  });

  // ── subtotal ──────────────────────────────────────────────────────────────

  test('subtotal refleja la suma de items del carrito', () async {
    when(() => api.getCarrito()).thenAnswer((_) async => carritoConItem());

    await provider.cargarCarrito();

    expect(provider.subtotal, 1500);
  });
}
