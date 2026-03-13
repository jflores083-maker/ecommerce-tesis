import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService _api;

  bool _loading = false;
  String? _error;
  bool _exito = false;

  AdminProvider(this._api);

  bool    get loading => _loading;
  String? get error   => _error;
  bool    get exito   => _exito;

  Future<Producto?> crearProducto({
    required String titulo,
    required String descripcion,
    required double precio,
    required int stock,
    required List<String> talles,
    required String categoria,
    required String estado,
    String? color,
    XFile? imagen,
  }) async {
    _loading = true;
    _error = null;
    _exito = false;
    notifyListeners();

    try {
      final tallesJson = '[${talles.map((t) => '"$t"').join(',')}]';
      final producto = await _api.crearProducto(
        titulo:      titulo,
        descripcion: descripcion,
        precio:      precio,
        stock:       stock,
        talles:      tallesJson,
        categoria:   categoria,
        estado:      estado,
        color:       color,
        imagen:      imagen,
      );
      _exito = true;
      _loading = false;
      notifyListeners();
      return producto;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return null;
    }
  }

  List<Producto> _misProductos = [];
  List<Producto> get misProductos => _misProductos;

  Future<void> cargarMisProductos() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _misProductos = await _api.getMisProductos();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> modificarProducto(int id, Map<String, dynamic> campos) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.actualizarProducto(id, campos);
      await cargarMisProductos();
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarProducto(int id) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _api.eliminarProducto(id);
      _misProductos.removeWhere((p) => p.id == id);
      _loading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void clearState() {
    _error = null;
    _exito = false;
    notifyListeners();
  }
}
