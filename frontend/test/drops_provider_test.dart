import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:app_638/providers/drops_provider.dart';
import 'mocks.dart';

void main() {
  late MockApiService api;
  late DropsProvider provider;

  setUp(() {
    api = MockApiService();
    provider = DropsProvider(api);
  });

  // ── cargarDrops ───────────────────────────────────────────────────────────

  group('cargarDrops', () {
    test('cuando la API retorna datos, popula la lista', () async {
      when(() => api.getDrops()).thenAnswer((_) async => [
        {
          'id': 1,
          'nombre': 'Drop Verano',
          'imagenUrl': null,
          'fechaCreacion': '2024-01-01T00:00:00Z',
          'totalProductos': 3,
        },
      ]);

      await provider.cargarDrops();

      expect(provider.drops.length, 1);
      expect(provider.drops.first.nombre, 'Drop Verano');
      expect(provider.drops.first.totalProductos, 3);
      expect(provider.cargando, false);
    });

    test('cuando la API retorna lista vacía, drops queda vacío', () async {
      when(() => api.getDrops()).thenAnswer((_) async => []);

      await provider.cargarDrops();

      expect(provider.drops, isEmpty);
      expect(provider.cargando, false);
    });

    test('cuando la API lanza excepción, guarda el error y cargando es false', () async {
      when(() => api.getDrops()).thenThrow(Exception('Error de red'));

      await provider.cargarDrops();

      expect(provider.drops, isEmpty);
      expect(provider.cargando, false);
      expect(provider.error, isNotNull);
    });
  });

  // ── eliminarDrop ──────────────────────────────────────────────────────────

  group('eliminarDrop', () {
    setUp(() {
      when(() => api.getDrops()).thenAnswer((_) async => [
        {
          'id': 1,
          'nombre': 'Drop Test',
          'imagenUrl': null,
          'fechaCreacion': '2024-01-01T00:00:00Z',
          'totalProductos': 2,
        },
      ]);
    });

    test('elimina el drop de la lista local y retorna true', () async {
      await provider.cargarDrops();
      when(() => api.eliminarDrop(1)).thenAnswer((_) async {});

      final result = await provider.eliminarDrop(1);

      expect(result, true);
      expect(provider.drops, isEmpty);
    });

    test('cuando la API falla, retorna false y la lista no cambia', () async {
      await provider.cargarDrops();
      when(() => api.eliminarDrop(1)).thenThrow(Exception('Error'));

      final result = await provider.eliminarDrop(1);

      expect(result, false);
      expect(provider.drops.length, 1);
    });
  });

  // ── crearDrop ─────────────────────────────────────────────────────────────

  group('crearDrop', () {
    test('cuando la API tiene éxito, retorna true y recarga los drops', () async {
      when(() => api.crearDrop(
        nombre: any(named: 'nombre'),
        productoIds: any(named: 'productoIds'),
        imagen: any(named: 'imagen'),
      )).thenAnswer((_) async => {});

      when(() => api.getDrops()).thenAnswer((_) async => [
        {
          'id': 2,
          'nombre': 'Nuevo Drop',
          'imagenUrl': null,
          'fechaCreacion': '2024-06-01T00:00:00Z',
          'totalProductos': 0,
        },
      ]);

      final result = await provider.crearDrop(
        nombre: 'Nuevo Drop',
        productoIds: [],
      );

      expect(result, true);
      expect(provider.drops.length, 1);
      expect(provider.drops.first.nombre, 'Nuevo Drop');
    });

    test('cuando la API falla, retorna false y guarda el error', () async {
      when(() => api.crearDrop(
        nombre: any(named: 'nombre'),
        productoIds: any(named: 'productoIds'),
        imagen: any(named: 'imagen'),
      )).thenThrow(Exception('Error'));

      final result = await provider.crearDrop(nombre: 'Drop', productoIds: []);

      expect(result, false);
      expect(provider.error, isNotNull);
    });
  });

  // ── getDropsPorProducto ───────────────────────────────────────────────────

  group('getDropsPorProducto', () {
    test('retorna los ids que devuelve la API', () async {
      when(() => api.getDropsPorProducto(5)).thenAnswer((_) async => [1, 3]);

      final ids = await provider.getDropsPorProducto(5);

      expect(ids, [1, 3]);
    });

    test('cuando la API falla, retorna lista vacía', () async {
      when(() => api.getDropsPorProducto(any())).thenThrow(Exception('Error'));

      final ids = await provider.getDropsPorProducto(99);

      expect(ids, isEmpty);
    });
  });

  // ── sincronizarProductoConDrops ───────────────────────────────────────────

  group('sincronizarProductoConDrops', () {
    test('agrega drops nuevos y quita los que ya no están seleccionados', () async {
      when(() => api.getDropsPorProducto(10)).thenAnswer((_) async => [1, 2]);
      when(() => api.agregarProductoADrop(3, 10)).thenAnswer((_) async {});
      when(() => api.quitarProductoDeDrop(1, 10)).thenAnswer((_) async {});
      when(() => api.getDrops()).thenAnswer((_) async => []);

      await provider.sincronizarProductoConDrops(10, [2, 3]);

      verify(() => api.agregarProductoADrop(3, 10)).called(1);
      verify(() => api.quitarProductoDeDrop(1, 10)).called(1);
      verifyNever(() => api.agregarProductoADrop(2, 10));
      verifyNever(() => api.quitarProductoDeDrop(2, 10));
    });
  });
}
