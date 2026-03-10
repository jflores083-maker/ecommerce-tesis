import 'package:flutter/foundation.dart';
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
