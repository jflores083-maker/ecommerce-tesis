import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class DropsProvider extends ChangeNotifier {
  final ApiService _api;

  List<Drop> _drops = [];
  bool _cargando = false;

  DropsProvider(this._api);

  List<Drop> get drops => _drops;
  bool get cargando => _cargando;

  Future<void> cargarDrops() async {
    _cargando = true;
    notifyListeners();
    try {
      final data = await _api.getDrops();
      _drops = data.map((j) => Drop.fromJson(j)).toList();
    } catch (_) {}
    _cargando = false;
    notifyListeners();
  }

  Future<DropDetalle?> getDetalle(int id) async {
    try {
      final data = await _api.getDrop(id);
      return DropDetalle.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<bool> crearDrop({
    required String nombre,
    required List<int> productoIds,
    XFile? imagen,
  }) async {
    try {
      await _api.crearDrop(nombre: nombre, productoIds: productoIds, imagen: imagen);
      await cargarDrops();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> eliminarDrop(int id) async {
    try {
      await _api.eliminarDrop(id);
      _drops.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
