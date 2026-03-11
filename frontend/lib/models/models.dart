import 'dart:convert';

// ─── Producto (mapea ProductoResponseDto / ProductoListaDto) ───
class Producto {
  final int id;
  final int vendedorId;
  final String titulo;
  final String descripcion;
  final double precio;
  final int stock;
  final List<String> talles;   // Talles viene como JSON string en el backend
  final String categoria;
  final String estado;         // "disponible" | etc.
  final String? color;
  final DateTime fechaPublicacion;
  final bool activo;
  final String vendedorNombre;
  final String? imagenPrincipalUrl;

  const Producto({
    required this.id,
    required this.vendedorId,
    required this.titulo,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.talles,
    required this.categoria,
    required this.estado,
    this.color,
    required this.fechaPublicacion,
    required this.activo,
    required this.vendedorNombre,
    this.imagenPrincipalUrl,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    // Talles: puede venir como string JSON '["S","M","L"]' o como lista
    List<String> parseTalles(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return List<String>.from(raw);
      try {
        final decoded = jsonDecode(raw as String);
        if (decoded is List) return List<String>.from(decoded);
      } catch (_) {}
      return [];
    }

    return Producto(
      id:                  (json['id'] as num).toInt(),
      vendedorId:          (json['vendedorId'] as num? ?? 0).toInt(),
      titulo:              json['titulo'] ?? '',
      descripcion:         json['descripcion'] ?? '',
      precio:              (json['precio'] as num).toDouble(),
      stock:               (json['stock'] as num? ?? 0).toInt(),
      talles:              parseTalles(json['talles']),
      categoria:           json['categoria'] ?? '',
      estado:              json['estado'] ?? '',
      color:               json['color'],
      fechaPublicacion:    DateTime.tryParse(json['fechaPublicacion'] ?? '') ?? DateTime.now(),
      activo:              json['activo'] ?? true,
      vendedorNombre:      json['vendedorNombre'] ?? '',
      imagenPrincipalUrl:  json['imagenPrincipalUrl'],
    );
  }

  // Precio formateado: $89.990
  String get precioFormateado =>
      '\$${precio.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  bool get disponible => estado.toLowerCase() == 'disponible' && activo;
}

// ─── ItemCarritoDto ────────────────────────────────────────
class ItemCarrito {
  final int id;           // itemId (usado para PUT y DELETE)
  final int productoId;
  final String titulo;
  final String? imagenPrincipalUrl;
  final String talle;
  int cantidad;
  final double precioUnitarioVigente;

  ItemCarrito({
    required this.id,
    required this.productoId,
    required this.titulo,
    this.imagenPrincipalUrl,
    required this.talle,
    required this.cantidad,
    required this.precioUnitarioVigente,
  });

  factory ItemCarrito.fromJson(Map<String, dynamic> json) {
    return ItemCarrito(
      id:                    (json['id'] as num).toInt(),
      productoId:            (json['productoId'] as num).toInt(),
      titulo:                json['titulo'] ?? '',
      imagenPrincipalUrl:    json['imagenPrincipalUrl'],
      talle:                 json['talle'] ?? '',
      cantidad:              (json['cantidad'] as num).toInt(),
      precioUnitarioVigente: (json['precioUnitarioVigente'] as num).toDouble(),
    );
  }

  double get subtotal => cantidad * precioUnitarioVigente;

  String get subtotalFormateado =>
      '\$${subtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  String get precioFormateado =>
      '\$${precioUnitarioVigente.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
}

// ─── CarritoDto ────────────────────────────────────────────
class Carrito {
  final int carritoId;
  final List<ItemCarrito> items;

  const Carrito({required this.carritoId, required this.items});

  factory Carrito.fromJson(Map<String, dynamic> json) {
    return Carrito(
      carritoId: (json['carritoId'] as num).toInt(),
      items: (json['items'] as List? ?? [])
          .map((i) => ItemCarrito.fromJson(i))
          .toList(),
    );
  }

  double get subtotal => items.fold(0, (sum, i) => sum + i.subtotal);

  String get subtotalFormateado =>
      '\$${subtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  int get totalItems => items.fold(0, (sum, i) => sum + i.cantidad);
}

// ─── Usuario ───────────────────────────────────────────────
class AppUser {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String rol;
  final String? token;

  const AppUser({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.rol,
    this.token,
  });

  // Login solo devuelve { token } — el perfil se obtiene con GET /api/usuarios/perfil
  factory AppUser.fromToken(String token) => AppUser(
        id: 0, nombre: '', apellido: '', email: '',
        telefono: '', rol: '', token: token,
      );

  factory AppUser.fromJson(Map<String, dynamic> json, {String? token}) {
    return AppUser(
      id:       (json['id'] as num? ?? 0).toInt(),
      nombre:   json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      email:    json['email'] ?? '',
      telefono: json['telefono'] ?? '',
      rol:      json['rol'] ?? 'Cliente',
      token:    token,
    );
  }

  bool get isAdmin => rol == 'Admin';
}
