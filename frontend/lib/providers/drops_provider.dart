import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class DropsProvider extends ChangeNotifier {
  final ApiService _api;

  List<Drop> _drops = [];
  bool _cargando = false;
  String? _error;

  DropsProvider(this._api);

  List<Drop> get drops => _drops;
  bool get cargando => _cargando;
  String? get error => _error;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> cargarDrops() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _api.getDrops();
      _drops = data.map((j) => Drop.fromJson(j)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Error al cargar los drops.';
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<DropDetalle?> getDetalle(int id) async {
    try {
      final data = await _api.getDrop(id);
      return DropDetalle.fromJson(data);
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return null;
    } catch (_) {
      _error = 'Error al cargar el drop.';
      notifyListeners();
      return null;
    }
  }

  Future<bool> crearDrop({
    required String nombre,
    required List<int> productoIds,
    XFile? imagen,
  }) async {
    _error = null;
    try {
      await _api.crearDrop(nombre: nombre, productoIds: productoIds, imagen: imagen);
      await cargarDrops();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Error al crear el drop.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarDrop({
    required int id,
    required String nombre,
    required List<int> productoIds,
    XFile? imagen,
  }) async {
    _error = null;
    try {
      await _api.actualizarDrop(id: id, nombre: nombre, productoIds: productoIds, imagen: imagen);
      await cargarDrops();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Error al actualizar el drop.';
      notifyListeners();
      return false;
    }
  }

  Future<List<int>> getDropsPorProducto(int productoId) async {
    try {
      return await _api.getDropsPorProducto(productoId);
    } catch (_) {
      return [];
    }
  }

  Future<void> sincronizarProductoConDrops(int productoId, List<int> dropIdsSeleccionados) async {
    final actuales = await _api.getDropsPorProducto(productoId);
    final agregar  = dropIdsSeleccionados.where((id) => !actuales.contains(id));
    final quitar   = actuales.where((id) => !dropIdsSeleccionados.contains(id));
    for (final id in agregar) await _api.agregarProductoADrop(id, productoId);
    for (final id in quitar)  await _api.quitarProductoDeDrop(id, productoId);
    await cargarDrops();
  }

  Future<bool> eliminarDrop(int id) async {
    _error = null;
    try {
      await _api.eliminarDrop(id);
      _drops.removeWhere((d) => d.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Error al eliminar el drop.';
      notifyListeners();
      return false;
    }
  }
}
