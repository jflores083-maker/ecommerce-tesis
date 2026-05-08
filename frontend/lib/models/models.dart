import 'dart:convert';

// ─── Drop ──────────────────────────────────────────────────────
class Drop {
  final int id;
  final String nombre;
  final String? imagenUrl;
  final DateTime fechaCreacion;
  final int totalProductos;

  const Drop({
    required this.id,
    required this.nombre,
    this.imagenUrl,
    required this.fechaCreacion,
    required this.totalProductos,
  });

  factory Drop.fromJson(Map<String, dynamic> j) => Drop(
        id: j['id'] as int,
        nombre: j['nombre'] as String,
        imagenUrl: j['imagenUrl'] as String?,
        fechaCreacion: DateTime.parse(j['fechaCreacion'] as String),
        totalProductos: j['totalProductos'] as int? ?? 0,
      );
}

class DropDetalle {
  final int id;
  final String nombre;
  final String? imagenUrl;
  final DateTime fechaCreacion;
  final List<DropProductoItem> productos;

  const DropDetalle({
    required this.id,
    required this.nombre,
    this.imagenUrl,
    required this.fechaCreacion,
    required this.productos,
  });

  factory DropDetalle.fromJson(Map<String, dynamic> j) => DropDetalle(
        id: j['id'] as int,
        nombre: j['nombre'] as String,
        imagenUrl: j['imagenUrl'] as String?,
        fechaCreacion: DateTime.parse(j['fechaCreacion'] as String),
        productos: (j['productos'] as List)
            .map((p) => DropProductoItem.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}

class DropProductoItem {
  final int id;
  final String titulo;
  final double precio;
  final String estado;
  final String? imagenUrl;

  const DropProductoItem({
    required this.id,
    required this.titulo,
    required this.precio,
    required this.estado,
    this.imagenUrl,
  });

  factory DropProductoItem.fromJson(Map<String, dynamic> j) => DropProductoItem(
        id: j['id'] as int,
        titulo: j['titulo'] as String,
        precio: (j['precio'] as num).toDouble(),
        estado: j['estado'] as String,
        imagenUrl: j['imagenUrl'] as String?,
      );

  String get precioFormateado =>
      '\$${precio.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}';
}

// ─── Producto ──────────────────────────────────────────────────
class Producto {
  final int id;
  final int vendedorId;
  final String titulo;
  final String descripcion;
  final double precio;
  final int stock;
  final List<String> talles;
  final String categoria;
  final String estado;
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
      id: (json['id'] as num).toInt(),
      vendedorId: (json['vendedorId'] as num? ?? 0).toInt(),
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      precio: (json['precio'] as num).toDouble(),
      stock: (json['stock'] as num? ?? 0).toInt(),
      talles: parseTalles(json['talles']),
      categoria: json['categoria'] ?? '',
      estado: json['estado'] ?? '',
      color: json['color'],
      fechaPublicacion:
          DateTime.tryParse(json['fechaPublicacion'] ?? '') ?? DateTime.now(),
      activo: json['activo'] ?? true,
      vendedorNombre: json['vendedorNombre'] ?? '',
      imagenPrincipalUrl: json['imagenPrincipalUrl'],
    );
  }

  String get precioFormateado =>
      '\$${precio.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  bool get disponible => estado.toLowerCase() == 'disponible' && activo;

  String get precioTransferenciaFormateado {
    final descuento = precio * 0.9;
    return '\$${descuento.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
  }
}

// ─── ItemCarrito ───────────────────────────────────────────────
class ItemCarrito {
  final int id;
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
      id: (json['id'] as num).toInt(),
      productoId: (json['productoId'] as num).toInt(),
      titulo: json['titulo'] ?? '',
      imagenPrincipalUrl: json['imagenPrincipalUrl'],
      talle: json['talle'] ?? '',
      cantidad: (json['cantidad'] as num).toInt(),
      precioUnitarioVigente: (json['precioUnitarioVigente'] as num).toDouble(),
    );
  }

  double get subtotal => cantidad * precioUnitarioVigente;

  String get subtotalFormateado =>
      '\$${subtotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  String get precioFormateado =>
      '\$${precioUnitarioVigente.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
}

// ─── Carrito ───────────────────────────────────────────────────
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

// ─── AppUser ───────────────────────────────────────────────────
class AppUser {
  final int id;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String rol;
  final String? token;
  final String? fotoPerfilUrl;
  final bool emailConfirmado;

  const AppUser({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.rol,
    this.token,
    this.fotoPerfilUrl,
    this.emailConfirmado = false,
  });

  factory AppUser.fromToken(String token) => AppUser(
        id: 0,
        nombre: '',
        apellido: '',
        email: '',
        telefono: '',
        rol: '',
        token: token,
      );

  factory AppUser.fromJson(Map<String, dynamic> json, {String? token}) {
    return AppUser(
      id: (json['id'] as num? ?? 0).toInt(),
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      email: json['email'] ?? '',
      telefono: json['telefono'] ?? '',
      rol: json['rol'] ?? 'Cliente',
      token: token,
      fotoPerfilUrl: json['fotoPerfilUrl'],
      emailConfirmado: json['emailConfirmado'] as bool? ?? false,
    );
  }

  bool get isAdmin => rol == 'Admin';
}

// ─── Favorito ─────────────────────────────────────────────────
class Favorito {
  final int id;
  final int productoId;
  final DateTime fechaAgregado;
  final String titulo;
  final double precio;
  final String estado;
  final String categoria;
  final int stock;
  final String? imagenPrincipal;

  const Favorito({
    required this.id,
    required this.productoId,
    required this.fechaAgregado,
    required this.titulo,
    required this.precio,
    required this.estado,
    required this.categoria,
    required this.stock,
    this.imagenPrincipal,
  });

  factory Favorito.fromJson(Map<String, dynamic> j) {
    final p = j['producto'] as Map<String, dynamic>;
    return Favorito(
      id: (j['id'] as num).toInt(),
      productoId: (j['productoId'] as num).toInt(),
      fechaAgregado: DateTime.parse(j['fechaAgregado'] as String),
      titulo: p['titulo'] ?? '',
      precio: (p['precio'] as num).toDouble(),
      estado: p['estado'] ?? '',
      categoria: p['categoria'] ?? '',
      stock: (p['stock'] as num? ?? 0).toInt(),
      imagenPrincipal: p['imagenPrincipal'],
    );
  }

  String get precioFormateado =>
      '\$${precio.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
}
