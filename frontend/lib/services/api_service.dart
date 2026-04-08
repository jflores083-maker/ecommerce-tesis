import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  // ── URL dinámica por plataforma ───────────────────────────
  // Web y iOS Simulator → localhost
  // Emulador Android    → 10.0.2.2 (alias del host en el emulador)
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:5005/api';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:5005/api';
    return 'http://localhost:5005/api'; // iOS, macOS, etc.
  }

  static String get serverUrl {
    if (kIsWeb) return 'http://localhost:5005';
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:5005';
    return 'http://localhost:5005';
  }
  // ─────────────────────────────────────────────────────────

  static const _tokenKey = 'auth_token';

  // ── Helpers ───────────────────────────────────────────────

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void _checkStatus(http.Response res) {
    if (res.statusCode >= 400) {
      String message;
      try {
        final body = jsonDecode(res.body);
        message = body is String
            ? body
            : (body['message'] ?? body['title'] ?? 'Error ${res.statusCode}');
      } catch (_) {
        message = res.body.isNotEmpty ? res.body : 'Error ${res.statusCode}';
      }
      throw ApiException(statusCode: res.statusCode, message: message);
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── AUTH ─────────────────────────────────────────────────
  // POST /api/auth/login → { token }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/login');
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    _checkStatus(res);
    final data = jsonDecode(res.body);
    final token = data['token'] as String;
    await _saveToken(token);
    return token;
  }

  // POST /api/auth/register
  // Body: { nombre, apellido, email, telefono, password }
  // Telefono debe comenzar con +54 y tener 10-12 dígitos
  Future<void> register({
    required String nombre,
    required String apellido,
    required String email,
    required String telefono,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/register');
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'nombre': nombre,
        'apellido': apellido,
        'email': email,
        'telefono': telefono,
        'password': password,
      }),
    );
    _checkStatus(res);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  // ── USUARIOS ─────────────────────────────────────────────
  // GET /api/usuarios/perfil → UsuarioResponseDto

  Future<AppUser> getMiPerfil() async {
    final uri = Uri.parse('$_baseUrl/usuarios/perfil');
    final res = await http.get(uri, headers: await _headers(auth: true));
    _checkStatus(res);
    final token = await getToken();
    return AppUser.fromJson(jsonDecode(res.body), token: token);
  }

  // PUT /api/usuarios/perfil
  Future<AppUser> actualizarPerfil({
    required String nombre,
    required String apellido,
    required String telefono,
    String? passwordActual,
    String? passwordNueva,
  }) async {
    final uri = Uri.parse('$_baseUrl/usuarios/perfil');
    final body = <String, dynamic>{
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
    };
    if (passwordNueva != null && passwordNueva.isNotEmpty) {
      body['passwordActual'] = passwordActual;
      body['passwordNueva']  = passwordNueva;
    }
    final res = await http.put(
      uri,
      headers: await _headers(auth: true),
      body: jsonEncode(body),
    );
    _checkStatus(res);
    final token = await getToken();
    return AppUser.fromJson(jsonDecode(res.body), token: token);
  }

  // ── PRODUCTOS ─────────────────────────────────────────────
  // GET /api/productos?categoria=&estado=
  // Devuelve lista de ProductoListaDto

  Future<List<Producto>> getProductos({
    String? categoria,
    String? estado,
  }) async {
    final params = <String, String>{};
    if (categoria != null && categoria.isNotEmpty)
      params['categoria'] = categoria;
    if (estado != null && estado.isNotEmpty) params['estado'] = estado;

    final uri = Uri.parse('$_baseUrl/productos')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri, headers: await _headers());
    _checkStatus(res);

    final List data = jsonDecode(res.body);
    return data.map((j) => Producto.fromJson(j)).toList();
  }

  // GET /api/productos/{id} → ProductoResponseDto

  Future<Producto> getProducto(int id) async {
    final uri = Uri.parse('$_baseUrl/productos/$id');
    final res = await http.get(uri, headers: await _headers());
    _checkStatus(res);
    return Producto.fromJson(jsonDecode(res.body));
  }

  // POST /api/productos (multipart/form-data) — solo Admin
  // Crea un nuevo producto con imagen opcional

  Future<Producto> crearProducto({
    required String titulo,
    required String descripcion,
    required double precio,
    required int stock,
    required String talles,     // JSON string: '["S","M","L"]'
    required String categoria,
    required String estado,
    String? color,
    XFile? imagen,
  }) async {
    final uri = Uri.parse('$_baseUrl/productos');
    final token = await getToken();

    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.fields['titulo']      = titulo;
    request.fields['descripcion'] = descripcion;
    request.fields['precio']      = precio.toString();
    request.fields['stock']       = stock.toString();
    request.fields['talles']      = talles;
    request.fields['categoria']   = categoria;
    request.fields['estado']      = estado;
    if (color != null && color.isNotEmpty) request.fields['color'] = color;

    if (imagen != null) {
      final bytes = await imagen.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'imagen', bytes,
        filename: imagen.name,
      ));
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _checkStatus(res);
    return Producto.fromJson(jsonDecode(res.body));
  }

  // GET /api/productos/mis-productos (requiere auth — solo vendedor)

  Future<List<Producto>> getMisProductos() async {
    final uri = Uri.parse('$_baseUrl/productos/mis-productos');
    final res = await http.get(uri, headers: await _headers(auth: true));
    _checkStatus(res);
    final List data = jsonDecode(res.body);
    return data.map((j) => Producto.fromJson(j)).toList();
  }

  // ── CONFIGURACIÓN ────────────────────────────────────────

  Future<Map<String, dynamic>> getConfiguracion() async {
    final uri = Uri.parse('$_baseUrl/configuracion');
    final res = await http.get(uri, headers: await _headers());
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> subirFotoPerfil(XFile imagen) async {
    final uri = Uri.parse('$_baseUrl/usuarios/perfil/foto');
    final token = await getToken();
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    final bytes = await imagen.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes('imagen', bytes, filename: imagen.name));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAcercaDe() async {
    final uri = Uri.parse('$_baseUrl/configuracion/acerca');
    final res = await http.get(uri, headers: await _headers());
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> guardarAcercaDe({required String titulo, required String descripcion}) async {
    final uri = Uri.parse('$_baseUrl/configuracion/acerca');
    final res = await http.put(
      uri,
      headers: await _headers(auth: true),
      body: jsonEncode({'titulo': titulo, 'descripcion': descripcion}),
    );
    _checkStatus(res);
  }

  Future<void> guardarContacto({
    required String email,
    required String telefono,
    required String direccion,
    required String horario,
  }) async {
    final uri = Uri.parse('$_baseUrl/configuracion/contacto');
    final res = await http.put(
      uri,
      headers: await _headers(auth: true),
      body: jsonEncode({'email': email, 'telefono': telefono, 'direccion': direccion, 'horario': horario}),
    );
    _checkStatus(res);
  }

  Future<Map<String, dynamic>> subirHeroImage(XFile imagen) async {
    final uri = Uri.parse('$_baseUrl/configuracion/hero');
    final token = await getToken();
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    final bytes = await imagen.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes('imagen', bytes, filename: imagen.name));
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // PUT /api/productos/{id}
  Future<void> actualizarProducto(int id, Map<String, dynamic> campos) async {
    final uri = Uri.parse('$_baseUrl/productos/$id');
    final res = await http.put(
      uri,
      headers: await _headers(auth: true),
      body: jsonEncode(campos),
    );
    _checkStatus(res);
  }

  // DELETE /api/productos/{id} (borrado lógico)
  Future<void> eliminarProducto(int id) async {
    final uri = Uri.parse('$_baseUrl/productos/$id');
    final res = await http.delete(uri, headers: await _headers(auth: true));
    _checkStatus(res);
  }

  // ── CARRITO ───────────────────────────────────────────────
  // GET /api/carrito → CarritoDto

  Future<Carrito> getCarrito() async {
    final uri = Uri.parse('$_baseUrl/carrito');
    final res = await http.get(uri, headers: await _headers(auth: true));
    _checkStatus(res);
    return Carrito.fromJson(jsonDecode(res.body));
  }

  // POST /api/carrito/items
  // Body: { productoId, cantidad (1-100), talle }
  // Si el item ya existe, suma la cantidad automáticamente

  Future<Carrito> agregarItem({
    required int productoId,
    required String talle,
    int cantidad = 1,
  }) async {
    final uri = Uri.parse('$_baseUrl/carrito/items');
    final res = await http.post(
      uri,
      headers: await _headers(auth: true),
      body: jsonEncode({
        'productoId': productoId,
        'talle': talle,
        'cantidad': cantidad,
      }),
    );
    _checkStatus(res);
    return Carrito.fromJson(jsonDecode(res.body));
  }

  // PUT /api/carrito/items/{itemId}
  // Body: { cantidad (1-100) }
  // Nota: usa el itemId del ItemCarrito, NO el productoId

  Future<Carrito> actualizarItem({
    required int itemId,
    required int cantidad,
  }) async {
    final uri = Uri.parse('$_baseUrl/carrito/items/$itemId');
    final res = await http.put(
      uri,
      headers: await _headers(auth: true),
      body: jsonEncode({'cantidad': cantidad}),
    );
    _checkStatus(res);
    return Carrito.fromJson(jsonDecode(res.body));
  }

  // DELETE /api/carrito/items/{itemId}

  Future<void> eliminarItem(int itemId) async {
    final uri = Uri.parse('$_baseUrl/carrito/items/$itemId');
    final res = await http.delete(uri, headers: await _headers(auth: true));
    _checkStatus(res);
    // Devuelve 204 NoContent
  }

  // DELETE /api/carrito — vaciar todo el carrito

  Future<void> vaciarCarrito() async {
    final uri = Uri.parse('$_baseUrl/carrito');
    final res = await http.delete(uri, headers: await _headers(auth: true));
    _checkStatus(res);
  }

  // POST /api/ordenes — crear orden desde el carrito
  Future<Map<String, dynamic>> crearOrden({
    required String direccionEnvio,
    required String ciudad,
    required String codigoPostal,
  }) async {
    final uri = Uri.parse('$_baseUrl/ordenes');
    final res = await http.post(
      uri,
      headers: await _headers(auth: true),
      body: jsonEncode({
        'direccionEnvio': direccionEnvio,
        'ciudad': ciudad,
        'codigoPostal': codigoPostal,
      }),
    );
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── DROPS ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getDrops() async {
    final uri = Uri.parse('$_baseUrl/drops');
    final res = await http.get(uri, headers: await _headers());
    _checkStatus(res);
    return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> getDrop(int id) async {
    final uri = Uri.parse('$_baseUrl/drops/$id');
    final res = await http.get(uri, headers: await _headers());
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> crearDrop({
    required String nombre,
    required List<int> productoIds,
    XFile? imagen,
  }) async {
    final uri = Uri.parse('$_baseUrl/drops');
    final token = await getToken();
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.fields['nombre'] = nombre;
    if (productoIds.isNotEmpty) {
      request.fields['productoIds'] = productoIds.join(',');
    }
    if (imagen != null) {
      final bytes = await imagen.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('imagen', bytes, filename: imagen.name));
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> actualizarDrop({
    required int id,
    required String nombre,
    required List<int> productoIds,
    XFile? imagen,
  }) async {
    final uri = Uri.parse('$_baseUrl/drops/$id');
    final token = await getToken();
    final request = http.MultipartRequest('PUT', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.fields['nombre'] = nombre;
    if (productoIds.isNotEmpty) {
      request.fields['productoIds'] = productoIds.join(',');
    }
    if (imagen != null) {
      final bytes = await imagen.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('imagen', bytes, filename: imagen.name));
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _checkStatus(res);
  }

  Future<List<int>> getProductosDelDrop(int dropId) async {
    final uri = Uri.parse('$_baseUrl/drops/$dropId/productos');
    final res = await http.get(uri, headers: await _headers(auth: true));
    _checkStatus(res);
    return (jsonDecode(res.body) as List).cast<int>();
  }

  Future<List<int>> getDropsPorProducto(int productoId) async {
    final uri = Uri.parse('$_baseUrl/drops/por-producto/$productoId');
    final res = await http.get(uri, headers: await _headers());
    _checkStatus(res);
    return (jsonDecode(res.body) as List).cast<int>();
  }

  Future<void> agregarProductoADrop(int dropId, int productoId) async {
    final uri = Uri.parse('$_baseUrl/drops/$dropId/productos/$productoId');
    final res = await http.post(uri, headers: await _headers(auth: true));
    _checkStatus(res);
  }

  Future<void> quitarProductoDeDrop(int dropId, int productoId) async {
    final uri = Uri.parse('$_baseUrl/drops/$dropId/productos/$productoId');
    final res = await http.delete(uri, headers: await _headers(auth: true));
    _checkStatus(res);
  }

  Future<void> eliminarDrop(int id) async {
    final uri = Uri.parse('$_baseUrl/drops/$id');
    final res = await http.delete(uri, headers: await _headers(auth: true));
    _checkStatus(res);
  }

  // ── Dashboard ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboard() async {
    final uri = Uri.parse('$_baseUrl/dashboard');
    final res = await http.get(uri, headers: await _headers(auth: true));
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Ajuste de precios ─────────────────────────────────────

  Future<Map<String, dynamic>> ajustarPrecios({
    required List<int> productoIds,
    required double porcentaje,
  }) async {
    final uri = Uri.parse('$_baseUrl/productos/ajustar-precios');
    final res = await http.patch(uri,
      headers: await _headers(auth: true),
      body: jsonEncode({'productoIds': productoIds, 'porcentaje': porcentaje}),
    );
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Códigos de promoción ──────────────────────────────────

  Future<List<dynamic>> getCodigosPromocion() async {
    final uri = Uri.parse('$_baseUrl/promociones');
    final res = await http.get(uri, headers: await _headers(auth: true));
    _checkStatus(res);
    return jsonDecode(res.body) as List;
  }

  Future<void> crearCodigoPromocion({
    required String codigo,
    required String tipo,
    required double valor,
    DateTime? fechaExpiracion,
    int? usosMaximos,
  }) async {
    final uri = Uri.parse('$_baseUrl/promociones');
    final body = <String, dynamic>{
      'codigo': codigo,
      'tipo': tipo,
      'valor': valor,
      if (fechaExpiracion != null) 'fechaExpiracion': fechaExpiracion.toIso8601String(),
      if (usosMaximos != null) 'usosMaximos': usosMaximos,
    };
    final res = await http.post(uri,
      headers: await _headers(auth: true),
      body: jsonEncode(body),
    );
    _checkStatus(res);
  }

  Future<void> eliminarCodigoPromocion(int id) async {
    final uri = Uri.parse('$_baseUrl/promociones/$id');
    final res = await http.delete(uri, headers: await _headers(auth: true));
    _checkStatus(res);
  }

  Future<Map<String, dynamic>> validarCodigoPromocion({
    required String codigo,
    required double subtotal,
  }) async {
    final uri = Uri.parse('$_baseUrl/promociones/validar');
    final res = await http.post(uri,
      headers: await _headers(auth: true),
      body: jsonEncode({'codigo': codigo, 'subtotal': subtotal}),
    );
    _checkStatus(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Órdenes admin ─────────────────────────────────────────

  Future<List<dynamic>> getTodasOrdenes({String? estado}) async {
    final params = estado != null ? '?estado=$estado' : '';
    final uri = Uri.parse('$_baseUrl/ordenes/todas$params');
    final res = await http.get(uri, headers: await _headers(auth: true));
    _checkStatus(res);
    return jsonDecode(res.body) as List;
  }

  Future<void> actualizarEstadoOrden(int id, String estado, {String? numeroSeguimiento}) async {
    final uri = Uri.parse('$_baseUrl/ordenes/$id/estado');
    final body = <String, dynamic>{'estado': estado};
    if (numeroSeguimiento != null) body['numeroSeguimiento'] = numeroSeguimiento;
    final res = await http.patch(uri,
      headers: await _headers(auth: true),
      body: jsonEncode(body),
    );
    _checkStatus(res);
  }
}

// ── Excepción custom ──────────────────────────────────────
class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isBadRequest => statusCode == 400;
}
