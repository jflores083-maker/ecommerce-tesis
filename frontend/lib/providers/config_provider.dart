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
  String _contactoEmail = '';
  String _contactoTelefono = '';
  String _contactoDireccion = '';
  String _contactoHorario = '';
  static const _kEnvioDefault = 'Envío gratis en compras mayores a \$60.000. Entrega en 3-5 días hábiles.';
  static const _kCategoriasDefault = ['Remeras','Pantalones','Buzos','Abrigos','Accesorios','Calzado','Otros'];
  String _envioTexto = _kEnvioDefault;
  List<String> _categorias = List.of(_kCategoriasDefault);

  ConfigProvider(this._api);

  int         get temaIndex          => _temaIndex;
  String?     get heroImageUrl       => _heroImageUrl;
  AppPaleta   get paleta             => AppPaleta.todas[_temaIndex];
  String      get acercaTitulo        => _acercaTitulo;
  String      get acercaDescripcion   => _acercaDescripcion;
  String      get contactoEmail       => _contactoEmail;
  String      get contactoTelefono    => _contactoTelefono;
  String      get contactoDireccion   => _contactoDireccion;
  String      get contactoHorario     => _contactoHorario;
  String      get envioTexto          => _envioTexto.isNotEmpty ? _envioTexto : _kEnvioDefault;
  List<String> get categorias         => _categorias.isNotEmpty ? _categorias : List.of(_kCategoriasDefault);

  Future<void> cargarConfig() async {
    // Cargar tema guardado localmente
    final prefs = await SharedPreferences.getInstance();
    _temaIndex = prefs.getInt('temaIndex') ?? 0;

    // Cargar hero image y acerca del backend
    try {
      final config = await _api.getConfiguracion();
      _heroImageUrl        = config['heroImageUrl']     as String?;
      _acercaTitulo        = (config['acercaTitulo']     as String?) ?? 'Sobre 638';
      _acercaDescripcion   = (config['acercaDescripcion'] as String?) ?? '';
      _contactoEmail       = (config['contactoEmail']    as String?) ?? '';
      _contactoTelefono    = (config['contactoTelefono'] as String?) ?? '';
      _contactoDireccion   = (config['contactoDireccion'] as String?) ?? '';
      _contactoHorario     = (config['contactoHorario']  as String?) ?? '';
      _envioTexto          = (config['envioTexto']        as String?) ?? _envioTexto;
      final cats = config['categorias'];
      if (cats is List && cats.isNotEmpty) {
        _categorias = cats.whereType<String>().toList();
      }
    } catch (_) {}

    notifyListeners();
  }

  Future<bool> guardarContacto({
    required String email, required String telefono,
    required String direccion, required String horario,
  }) async {
    try {
      await _api.guardarContacto(email: email, telefono: telefono, direccion: direccion, horario: horario);
      _contactoEmail     = email;
      _contactoTelefono  = telefono;
      _contactoDireccion = direccion;
      _contactoHorario   = horario;
      notifyListeners();
      return true;
    } catch (_) { return false; }
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

  Future<bool> guardarCategorias(List<String> cats) async {
    try {
      await _api.guardarCategorias(cats);
      _categorias = List.of(cats);
      notifyListeners();
      return true;
    } catch (_) { return false; }
  }

  Future<bool> guardarEnvio({required String texto}) async {
    try {
      await _api.guardarEnvio(texto: texto);
      _envioTexto = texto;
      notifyListeners();
      return true;
    } catch (_) { return false; }
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
