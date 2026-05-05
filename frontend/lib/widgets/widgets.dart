import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_constants.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/carrito_provider.dart';
import '../providers/productos_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// ─── APP NAVBAR ────────────────────────────────────────────
class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  void _openMobileMenu(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final location = GoRouterState.of(context).matchedLocation;
    final productosProvider = context.read<ProductosProvider>();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'menu',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        return Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: 280,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
                child: _MobileMenuPanel(
                  auth: auth,
                  isOnCatalog: location == '/catalogo',
                  productosProvider: productosProvider,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();
    final auth = context.watch<AuthProvider>();
    final isMobile = MediaQuery.of(context).size.width <= 768;

    final location = GoRouterState.of(context).matchedLocation;
    final canGoBack = location != '/';

    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: canGoBack
          ? IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else if (location.startsWith('/producto/')) {
                  context.go('/catalogo');
                } else if (location.startsWith('/drops/')) {
                  context.go('/drops');
                } else if (location.startsWith('/admin/')) {
                  context.go('/admin');
                } else {
                  context.go('/');
                }
              },
              icon: const Icon(Icons.arrow_back,
                  size: 18, color: AppColors.charcoal),
              splashRadius: 20,
            )
          : null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.sand),
      ),
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: Text(
          'Urbal',
          style: GoogleFonts.syne(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -0.5,
          ),
        ),
      ),
      actions: [
        // Links de navegación (solo desktop)
        if (!isMobile) ...[
          _ColeccionDropdown(),
          _NavLink('Drops', () => context.go('/drops')),
          _NavLink('Acerca de', () => context.go('/acerca-de')),
          _NavLink('Contacto', () => context.go('/contacto')),
          const SizedBox(width: 12),
        ],
        // Carrito
        _CartButton(carrito: carrito),
        // Desktop: admin + auth
        if (!isMobile) ...[
          if (auth.isLoggedIn && (auth.user?.isAdmin ?? false))
            TextButton(
              onPressed: () => context.go('/admin'),
              child: Text(
                'Panel de Administración',
                style: GoogleFonts.dmMono(
                    fontSize: 11,
                    color: AppColors.charcoal,
                    letterSpacing: 0.1),
              ),
            ),
          if (!auth.isLoggedIn)
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text(
                'Ingresar',
                style: GoogleFonts.dmMono(
                    fontSize: 11,
                    color: AppColors.charcoal,
                    letterSpacing: 0.1),
              ),
            ),
          if (auth.isLoggedIn)
            PopupMenuButton<String>(
              icon: _UserAvatar(fotoUrl: auth.user?.fotoPerfilUrl),
              onSelected: (v) {
                if (v == 'perfil') context.go('/perfil');
                if (v == 'logout') context.read<AuthProvider>().logout();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'perfil',
                  child: Text(auth.user?.nombre ?? 'Perfil',
                      style: GoogleFonts.dmMono(fontSize: 12)),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Text('Cerrar sesión',
                      style: GoogleFonts.dmMono(fontSize: 12)),
                ),
              ],
            ),
        ],
        // Mobile: hamburger
        if (isMobile)
          IconButton(
            onPressed: () => _openMobileMenu(context),
            icon: const Icon(Icons.menu, color: AppColors.charcoal),
          ),
        const SizedBox(width: 8),
      ],
    );
  }
}

// ─── MOBILE MENU PANEL ─────────────────────────────────────
class _MobileMenuPanel extends StatelessWidget {
  final AuthProvider auth;
  final bool isOnCatalog;
  final ProductosProvider productosProvider;
  const _MobileMenuPanel({
    required this.auth,
    required this.isOnCatalog,
    required this.productosProvider,
  });

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cream,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del panel
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (auth.isLoggedIn)
                    Flexible(
                      child: Row(
                        children: [
                          _UserAvatar(fotoUrl: auth.user?.fotoPerfilUrl),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  auth.user?.nombre ?? '',
                                  style: GoogleFonts.syne(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  auth.user?.email ?? '',
                                  style: GoogleFonts.dmMono(
                                    fontSize: 10,
                                    color: AppColors.stone,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      'Urbal',
                      style: GoogleFonts.syne(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.5,
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close,
                        color: AppColors.charcoal, size: 20),
                  ),
                ],
              ),
            ),
            Container(height: 1, color: AppColors.sand),
            const SizedBox(height: 8),

            // Links de navegación
            _MenuColeccion(
              onSelectCategoria: (cat) {
                if (isOnCatalog) {
                  productosProvider.cargarProductos(categoria: cat);
                  Navigator.of(context).pop();
                } else {
                  _go(context,
                      cat == null ? '/catalogo' : '/catalogo?categoria=$cat');
                }
              },
            ),
            _MenuItem(label: 'Drops', onTap: () => _go(context, '/drops')),
            _MenuItem(
                label: 'Acerca de nosotros',
                onTap: () => _go(context, '/acerca-de')),
            _MenuItem(
                label: 'Contacto', onTap: () => _go(context, '/contacto')),

            if (auth.isLoggedIn && (auth.user?.isAdmin ?? false)) ...[
              Container(
                  height: 1,
                  color: AppColors.sand,
                  margin: const EdgeInsets.symmetric(vertical: 8)),
              _MenuItem(
                  label: 'Panel Admin', onTap: () => _go(context, '/admin')),
            ],

            Container(
                height: 1,
                color: AppColors.sand,
                margin: const EdgeInsets.symmetric(vertical: 8)),

            // Auth
            if (auth.isLoggedIn) ...[
              _MenuItem(
                label: auth.user?.nombre ?? 'Mi perfil',
                icon: Icons.person_outline,
                onTap: () => _go(context, '/perfil'),
              ),
              _MenuItem(
                label: 'Cerrar sesión',
                icon: Icons.logout,
                onTap: () {
                  Navigator.of(context).pop();
                  context.read<AuthProvider>().logout();
                },
              ),
            ] else
              _MenuItem(
                label: 'Ingresar',
                icon: Icons.login,
                onTap: () => _go(context, '/login'),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── COLECCIÓN EXPANDIBLE (mobile menu) ────────────────────
class _MenuColeccion extends StatefulWidget {
  final void Function(String? categoria) onSelectCategoria;
  const _MenuColeccion({required this.onSelectCategoria});

  @override
  State<_MenuColeccion> createState() => _MenuColeccionState();
}

class _MenuColeccionState extends State<_MenuColeccion> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Colección',
                  style: GoogleFonts.dmMono(
                    fontSize: 13,
                    color: AppColors.ink,
                    letterSpacing: 0.1,
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: const Icon(Icons.keyboard_arrow_down,
                      size: 16, color: AppColors.charcoal),
                ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          InkWell(
            onTap: () => widget.onSelectCategoria(null),
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 40, right: 24, top: 10, bottom: 10),
              child: Text(
                'Todos',
                style:
                    GoogleFonts.dmMono(fontSize: 12, color: AppColors.charcoal),
              ),
            ),
          ),
          ...AppCategorias.todas.map((cat) => InkWell(
                onTap: () => widget.onSelectCategoria(cat),
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 40, right: 24, top: 10, bottom: 10),
                  child: Text(
                    cat,
                    style: GoogleFonts.dmMono(
                        fontSize: 12, color: AppColors.charcoal),
                  ),
                ),
              )),
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  const _MenuItem({required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: AppColors.charcoal),
              const SizedBox(width: 12),
            ],
            Text(
              label,
              style: GoogleFonts.dmMono(
                fontSize: 13,
                color: AppColors.ink,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── COLECCIÓN DROPDOWN (desktop hover) ────────────────────
class _ColeccionDropdown extends StatefulWidget {
  @override
  State<_ColeccionDropdown> createState() => _ColeccionDropdownState();
}

class _ColeccionDropdownState extends State<_ColeccionDropdown> {
  bool _open = false;
  final _linkKey = GlobalKey();
  OverlayEntry? _overlay;
  Timer? _hideTimer;

  void _show() {
    _hideTimer?.cancel();
    if (_open) return;
    final box = _linkKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final location = GoRouterState.of(context).matchedLocation;
    final productosProvider = context.read<ProductosProvider>();

    _overlay = OverlayEntry(
      builder: (_) => _DropdownMenu(
        top: pos.dy + box.size.height,
        left: pos.dx,
        onClose: _scheduleHide,
        onCancelClose: _cancelHide,
        onSelectCategoria: (String? cat) {
          _hide();
          final ctx = _linkKey.currentContext;
          if (ctx == null || !ctx.mounted) return;
          if (location == '/catalogo') {
            productosProvider.cargarProductos(categoria: cat);
          } else {
            ctx.go(cat == null ? '/catalogo' : '/catalogo?categoria=$cat');
          }
        },
      ),
    );

    Overlay.of(context).insert(_overlay!);
    setState(() => _open = true);
  }

  void _scheduleHide() {
    _hideTimer = Timer(const Duration(milliseconds: 120), _hide);
  }

  void _cancelHide() {
    _hideTimer?.cancel();
  }

  void _hide() {
    _hideTimer?.cancel();
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _open = false);
  }

  void _removeOverlaySilently() {
    _hideTimer?.cancel();
    _overlay?.remove();
    _overlay = null;
  }

  @override
  void dispose() {
    _removeOverlaySilently();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _show(),
      onExit: (_) => _scheduleHide(),
      child: TextButton(
        key: _linkKey,
        onPressed: () => context.go('/catalogo'),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'COLECCIÓN',
              style: GoogleFonts.dmMono(
                fontSize: 11,
                color: AppColors.gray,
                letterSpacing: 0.12,
              ),
            ),
            const SizedBox(width: 3),
            AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: const Icon(Icons.keyboard_arrow_down,
                  size: 14, color: AppColors.gray),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownMenu extends StatelessWidget {
  final double top;
  final double left;
  final VoidCallback onClose;
  final VoidCallback onCancelClose;
  final void Function(String? cat) onSelectCategoria;

  const _DropdownMenu({
    required this.top,
    required this.left,
    required this.onClose,
    required this.onCancelClose,
    required this.onSelectCategoria,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: MouseRegion(
        onEnter: (_) => onCancelClose(),
        onExit: (_) => onClose(),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 180,
            decoration: BoxDecoration(
              color: AppColors.cream,
              border: Border.all(color: AppColors.sand),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DropdownItem(
                  label: 'Todos',
                  onTap: () => onSelectCategoria(null),
                ),
                Container(height: 1, color: AppColors.sand),
                ...AppCategorias.todas.map((cat) => _DropdownItem(
                      label: cat,
                      onTap: () => onSelectCategoria(cat),
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownItem extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _DropdownItem({required this.label, required this.onTap});

  @override
  State<_DropdownItem> createState() => _DropdownItemState();
}

class _DropdownItemState extends State<_DropdownItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered ? AppColors.beige : AppColors.cream,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            widget.label,
            style: GoogleFonts.dmMono(
              fontSize: 11,
              color: _hovered ? AppColors.ink : AppColors.charcoal,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  final CarritoProvider carrito;
  const _CartButton({required this.carrito});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => context.go('/carrito'),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined,
              size: 18, color: AppColors.charcoal),
          const SizedBox(width: 6),
          if (MediaQuery.of(context).size.width > 480)
            Text(
              'Bolsa',
              style: GoogleFonts.dmMono(
                fontSize: 11,
                color: AppColors.charcoal,
                letterSpacing: 0.1,
              ),
            ),
          if (carrito.totalItems > 0) ...[
            const SizedBox(width: 6),
            Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${carrito.totalItems}',
                  style: const TextStyle(
                    color: AppColors.cream,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavLink(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmMono(
          fontSize: 11,
          color: AppColors.gray,
          letterSpacing: 0.12,
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final String? fotoUrl;
  const _UserAvatar({this.fotoUrl});

  @override
  Widget build(BuildContext context) {
    if (fotoUrl != null) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.sand),
        ),
        child: ClipOval(
          child: Image.network(
            '${ApiService.serverUrl}$fotoUrl',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.person_outline,
                size: 18, color: AppColors.charcoal),
          ),
        ),
      );
    }
    return const Icon(Icons.person_outline,
        size: 20, color: AppColors.charcoal);
  }
}

// ─── PRODUCT CARD ──────────────────────────────────────────
class ProductCard extends StatefulWidget {
  final Producto producto;
  const ProductCard({super.key, required this.producto});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.producto;

    return GestureDetector(
      onTap: () => context.go('/producto/${p.id}'),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo
                  AnimatedScale(
                    scale: _hovered ? 1.03 : 1.0,
                    duration: const Duration(milliseconds: 350),
                    child: _ProductImage(producto: p),
                  ),
                  // Badge SIN STOCK
                  if (!p.disponible)
                    const Positioned(
                      top: 12,
                      right: 12,
                      child: _Badge(label: 'SIN STOCK', dark: true),
                    ),
                  // Quick add (visible en hover desktop)
                  // Offstage mantiene el widget montado para que el async
                  // no pierda el context cuando el mouse sale durante la espera
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Offstage(
                      offstage: !_hovered || !p.disponible,
                      child: _QuickAdd(producto: p),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    p.titulo,
                    style: GoogleFonts.syne(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(
                    p.precioFormateado,
                    style: GoogleFonts.dmMono(
                      fontSize: 12,
                      color: AppColors.gray,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${p.precioTransferenciaFormateado} con Transferencia',
              style: GoogleFonts.dmMono(
                fontSize: 10,
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.05,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              p.categoria.toUpperCase(),
              style: GoogleFonts.dmMono(
                fontSize: 10,
                color: AppColors.stone,
                letterSpacing: 0.12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final Producto producto;
  const _ProductImage({required this.producto});

  @override
  Widget build(BuildContext context) {
    final url = producto.imagenPrincipalUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        '${ApiService.serverUrl}$url',
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : Container(color: AppColors.beige),
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.beige,
          child: Center(
            child: Icon(Icons.shopping_bag_outlined,
                size: 48, color: AppColors.stone.withOpacity(0.35)),
          ),
        ),
      );
    }
    return Container(
      color: AppColors.beige,
      child: Center(
        child: Icon(Icons.shopping_bag_outlined,
            size: 48, color: AppColors.stone.withOpacity(0.35)),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool dark;
  const _Badge({required this.label, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      color: dark ? AppColors.ink : AppColors.stone,
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmMono(
          fontSize: 9,
          color: AppColors.cream,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}

class _QuickAdd extends StatefulWidget {
  final Producto producto;
  const _QuickAdd({required this.producto});

  @override
  State<_QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<_QuickAdd> {
  bool _loading = false;

  Future<void> _onTap() async {
    if (_loading) return;

    // Producto no disponible → mostrar error inmediatamente
    if (!widget.producto.disponible) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          'Producto no disponible',
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream),
        ),
        backgroundColor: AppColors.charcoal,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Más de un talle → ir al detalle para que el usuario elija
    if (widget.producto.talles.length > 1) {
      context.go('/producto/${widget.producto.id}');
      return;
    }

    // Sin login → redirigir
    if (!context.read<AuthProvider>().isLoggedIn) {
      context.go('/login');
      return;
    }

    // Capturar referencias ANTES del await para no usar context tras gap asíncrono
    final messenger = ScaffoldMessenger.of(context);
    final carritoProvider = context.read<CarritoProvider>();

    setState(() => _loading = true);

    final talle = widget.producto.talles.isNotEmpty
        ? widget.producto.talles.first
        : 'Único';

    final ok = await carritoProvider.agregar(
      productoId: widget.producto.id,
      talle: talle,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    messenger.clearSnackBars();
    if (ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(
          '✓ ${widget.producto.titulo} agregado',
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream),
        ),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      final error = carritoProvider.error ?? 'No se pudo agregar';
      messenger.showSnackBar(SnackBar(
        content: Text(
          error,
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream),
        ),
        backgroundColor: AppColors.charcoal,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        color: AppColors.ink,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: _loading
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.cream,
                  ),
                )
              : Text(
                  widget.producto.disponible
                      ? '+ AGREGAR AL CARRITO'
                      : 'AGOTADO',
                  style: GoogleFonts.dmMono(
                    fontSize: 10,
                    color: AppColors.cream,
                    letterSpacing: 0.15,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── PRIMARY BUTTON ────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool fullWidth;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.cream,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        minimumSize: fullWidth ? const Size(double.infinity, 52) : null,
      ),
      child: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: AppColors.cream,
              ),
            )
          : Text(
              label.toUpperCase(),
              style: GoogleFonts.dmMono(
                fontSize: 11,
                letterSpacing: 0.18,
              ),
            ),
    );
    return btn;
  }
}

// ─── OUTLINE BUTTON ────────────────────────────────────────
class OutlineBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const OutlineBtn({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.charcoal),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.dmMono(
          fontSize: 11,
          color: AppColors.charcoal,
          letterSpacing: 0.15,
        ),
      ),
    );
  }
}

// ─── AUTH FIELD ────────────────────────────────────────────
// ─── AUTH FIELD ────────────────────────────────────────────
class AuthField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffix;
  final Widget? prefix; // ← AGREGAR
  final List<TextInputFormatter>? inputFormatters; // ← AGREGAR
  final VoidCallback? onSubmit;
  final String? hint;

  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.prefix, // ← AGREGAR
    this.inputFormatters, // ← AGREGAR
    this.onSubmit,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmMono(
            fontSize: 10,
            color: AppColors.gray,
            letterSpacing: 0.15,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters, // ← AGREGAR
          onSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
          style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.charcoal),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefix != null // ← AGREGAR ESTE BLOQUE COMPLETO
                ? Padding(
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    child: prefix,
                  )
                : null,
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12), child: suffix)
                : null,
            suffixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.sand),
            ),
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.sand),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.charcoal),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── ERROR WIDGET ──────────────────────────────────────────
class ErrorMsg extends StatelessWidget {
  final String message;
  const ErrorMsg(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFFFFF0F0),
      child: Text(
        message,
        style: GoogleFonts.dmMono(fontSize: 11, color: Colors.red[700]),
      ),
    );
  }
}
