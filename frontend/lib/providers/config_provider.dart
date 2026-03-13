import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ConfigProvider extends ChangeNotifier {
  final ApiService _api;

  int _temaIndex = 0;
  String? _heroImageUrl;
  String _acercaTitulo = 'Sobre 638';
  String _acercaDescripcion = '';

  ConfigProvider(this._api);

  int         get temaIndex          => _temaIndex;
  String?     get heroImageUrl       => _heroImageUrl;
  AppPaleta   get paleta             => AppPaleta.todas[_temaIndex];
  String      get acercaTitulo       => _acercaTitulo;
  String      get acercaDescripcion  => _acercaDescripcion;

  Future<void> cargarConfig() async {
    // Cargar tema guardado localmente
    final prefs = await SharedPreferences.getInstance();
    _temaIndex = prefs.getInt('temaIndex') ?? 0;

    // Cargar hero image y acerca del backend
    try {
      final config = await _api.getConfiguracion();
      _heroImageUrl       = config['heroImageUrl'] as String?;
      _acercaTitulo       = (config['acercaTitulo'] as String?) ?? 'Sobre 638';
      _acercaDescripcion  = (config['acercaDescripcion'] as String?) ?? '';
    } catch (_) {}

    notifyListeners();
  }

  Future<bool> guardarAcerca({required String titulo, required String descripcion}) async {
    try {
      await _api.guardarAcercaDe(titulo: titulo, descripcion: descripcion);
      _acercaTitulo = titulo;
      _acercaDescripcion = descripcion;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> setTema(int index) async {
    if (index < 0 || index >= AppPaleta.todas.length) return;
    _temaIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('temaIndex', index);
    notifyListeners();
  }

  Future<bool> subirHero(XFile imagen) async {
    try {
      final result = await _api.subirHeroImage(imagen);
      _heroImageUrl = result['heroImageUrl'] as String?;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void clearHero() {
    _heroImageUrl = null;
    notifyListeners();
  }
}
