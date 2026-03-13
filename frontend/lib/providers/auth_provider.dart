import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final ApiService _api;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  String? _error;
  bool _loading = false;

  AuthProvider(this._api) {
    _checkSession();
  }

  AuthStatus get status  => _status;
  AppUser?   get user    => _user;
  String?    get error   => _error;
  bool       get loading => _loading;
  bool       get isLoggedIn => _status == AuthStatus.authenticated;

  Future<void> _checkSession() async {
    final logged = await _api.isLoggedIn();
    if (logged) {
      try {
        _user = await _api.getMiPerfil();
        _status = AuthStatus.authenticated;
      } catch (_) {
        await _api.logout();
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.login(email: email, password: password);
      _user = await _api.getMiPerfil();
      _status = AuthStatus.authenticated;
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

  Future<bool> register({
    required String nombre,
    required String apellido,
    required String email,
    required String telefono,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _api.register(
        nombre: nombre,
        apellido: apellido,
        email: email,
        telefono: telefono,
        password: password,
      );
      // Después de registrar, hacer login automático
      await _api.login(email: email, password: password);
      _user = await _api.getMiPerfil();
      _status = AuthStatus.authenticated;
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

  Future<void> logout() async {
    await _api.logout();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> subirFotoPerfil(XFile imagen) async {
    try {
      final result = await _api.subirFotoPerfil(imagen);
      final fotoUrl = result['fotoPerfilUrl'] as String?;
      if (_user != null && fotoUrl != null) {
        _user = AppUser(
          id: _user!.id, nombre: _user!.nombre, apellido: _user!.apellido,
          email: _user!.email, telefono: _user!.telefono, rol: _user!.rol,
          token: _user!.token, fotoPerfilUrl: fotoUrl,
        );
        notifyListeners();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> actualizarPerfil({
    required String nombre,
    required String apellido,
    required String telefono,
    String? passwordActual,
    String? passwordNueva,
  }) async {
    _error = null;
    try {
      _user = await _api.actualizarPerfil(
        nombre: nombre,
        apellido: apellido,
        telefono: telefono,
        passwordActual: passwordActual,
        passwordNueva: passwordNueva,
      );
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
