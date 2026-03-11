import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class ProductosProvider extends ChangeNotifier {
  final ApiService _api;

  List<Producto> _productos = [];
  Producto? _productoDetalle;
  bool _loading = false;
  String? _error;
  String _categoriaActiva = '';

  ProductosProvider(this._api);

  List<Producto> get productos        => _productos;
  Producto?      get productoDetalle  => _productoDetalle;
  bool           get loading          => _loading;
  String?        get error            => _error;
  String         get categoriaActiva  => _categoriaActiva;

  Future<void> cargarProductos({String? categoria}) async {
    _loading = true;
    _error = null;
    _categoriaActiva = categoria ?? '';
    notifyListeners();

    try {
      _productos = await _api.getProductos(
        categoria: categoria,
      );
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> cargarDetalle(int id) async {
    _loading = true;
    _error = null;
    _productoDetalle = null;
    notifyListeners();

    try {
      _productoDetalle = await _api.getProducto(id);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
