import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class CarritoProvider extends ChangeNotifier {
  final ApiService _api;

  Carrito? _carrito;
  bool _loading = false;
  String? _error;

  CarritoProvider(this._api);

  Carrito? get carrito  => _carrito;
  bool     get loading  => _loading;
  String?  get error    => _error;

  List<ItemCarrito> get items       => _carrito?.items ?? [];
  int               get totalItems  => _carrito?.totalItems ?? 0;
  double            get subtotal    => _carrito?.subtotal ?? 0;
  String            get subtotalFormateado => _carrito?.subtotalFormateado ?? '\$0';

  // Carga el carrito desde el backend (llamar al hacer login)
  Future<void> cargarCarrito() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _carrito = await _api.getCarrito();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Agregar item — el backend unifica por (productoId + talle)
  Future<bool> agregar({
    required int productoId,
    required String talle,
    int cantidad = 1,
  }) async {
    _error = null;
    try {
      _carrito = await _api.agregarItem(
        productoId: productoId,
        talle: talle,
        cantidad: cantidad,
      );
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  // Actualizar cantidad de un item — usa itemId
  Future<void> actualizarCantidad({
    required int itemId,
    required int cantidad,
  }) async {
    if (cantidad < 1) return;
    try {
      _carrito = await _api.actualizarItem(itemId: itemId, cantidad: cantidad);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  // Eliminar item por itemId
  Future<void> eliminar(int itemId) async {
    try {
      await _api.eliminarItem(itemId);
      _carrito?.items.removeWhere((i) => i.id == itemId);
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  // Vaciar todo el carrito
  Future<void> vaciar() async {
    try {
      await _api.vaciarCarrito();
      _carrito = _carrito != null
          ? Carrito(carritoId: _carrito!.carritoId, items: [])
          : null;
      notifyListeners();
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
    }
  }

  // Confirmar compra — crea la orden y limpia el carrito
  Future<Map<String, dynamic>?> confirmarCompra({
    required String direccionEnvio,
    required String ciudad,
    required String codigoPostal,
  }) async {
    _error = null;
    _loading = true;
    notifyListeners();
    try {
      final result = await _api.crearOrden(
        direccionEnvio: direccionEnvio,
        ciudad: ciudad,
        codigoPostal: codigoPostal,
      );
      _carrito = _carrito != null
          ? Carrito(carritoId: _carrito!.carritoId, items: [])
          : null;
      _loading = false;
      notifyListeners();
      return result;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  void limpiarLocal() {
    _carrito = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
