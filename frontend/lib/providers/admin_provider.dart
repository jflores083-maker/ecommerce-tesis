import 'dart:io';
import 'package:flutter/foundation.dart';
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

  Future<bool> crearProducto({
    required String titulo,
    required String descripcion,
    required double precio,
    required int stock,
    required List<String> talles,
    required String categoria,
    required String estado,
    String? color,
    File? imagen,
  }) async {
    _loading = true;
    _error = null;
    _exito = false;
    notifyListeners();

    try {
      // Talles se serializa como JSON array string: ["S","M","L"]
      final tallesJson = '[${talles.map((t) => '"$t"').join(',')}]';

      await _api.crearProducto(
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
