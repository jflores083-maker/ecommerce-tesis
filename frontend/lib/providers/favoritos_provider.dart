import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class FavoritosProvider extends ChangeNotifier {
  final ApiService _api;

  List<Favorito> _favoritos = [];
  bool _loading = false;
  String? _error;

  FavoritosProvider(this._api);

  List<Favorito> get favoritos => _favoritos;
  bool get loading => _loading;
  String? get error => _error;
  int get total => _favoritos.length;

  bool esFavorito(int productoId) =>
      _favoritos.any((f) => f.productoId == productoId);

  Future<void> cargarFavoritos() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _favoritos = await _api.getFavoritos();
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleFavorito(int productoId) async {
    _error = null;
    try {
      if (esFavorito(productoId)) {
        await _api.eliminarFavorito(productoId);
        _favoritos.removeWhere((f) => f.productoId == productoId);
        notifyListeners();
        return false; // ya no es favorito
      } else {
        await _api.agregarFavorito(productoId);
        // recargamos para tener los datos completos del producto
        _favoritos = await _api.getFavoritos();
        notifyListeners();
        return true; // ahora es favorito
      }
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return esFavorito(productoId);
    }
  }

  void limpiarLocal() {
    _favoritos = [];
    notifyListeners();
  }
}
