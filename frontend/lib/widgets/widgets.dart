import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/carrito_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

// ─── APP NAVBAR ────────────────────────────────────────────
class AppNavBar extends StatelessWidget implements PreferredSizeWidget {
  const AppNavBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();
    final auth    = context.watch<AuthProvider>();

    final location = GoRouterState.of(context).matchedLocation;
    final canGoBack = location != '/';

    return AppBar(
      backgroundColor: AppColors.cream,
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
                } else {
                  context.go('/');
                }
              },
              icon: const Icon(Icons.arrow_back, size: 18, color: AppColors.charcoal),
              splashRadius: 20,
            )
          : null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.sand),
      ),
      title: GestureDetector(
        onTap: () => context.go('/'),
        child: Text('638',
          style: GoogleFonts.syne(
            fontSize: 22, fontWeight: FontWeight.w800,
            color: AppColors.ink, letterSpacing: -0.5,
          ),
        ),
      ),
      actions: [
        // Links de navegación (solo desktop/tablet)
        if (MediaQuery.of(context).size.width > 768) ...[
          _NavLink('Colección', () => context.go('/catalogo')),
          _NavLink('Acerca de', () {}),
          const SizedBox(width: 12),
        ],
        // Carrito
        GestureDetector(
          onTap: () => context.go('/carrito'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    size: 18, color: AppColors.charcoal),
                const SizedBox(width: 6),
                if (MediaQuery.of(context).size.width > 480)
                  Text('Bolsa',
                    style: GoogleFonts.dmMono(
                      fontSize: 11, color: AppColors.charcoal,
                      letterSpacing: 0.1,
                    ),
                  ),
                if (carrito.totalItems > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.ink, shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${carrito.totalItems}',
                        style: const TextStyle(
                          color: AppColors.cream, fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Botón Admin (solo visible para rol Admin)
        if (auth.isLoggedIn && (auth.user?.isAdmin ?? false))
          TextButton(
            onPressed: () => context.go('/admin'),
            child: Text('Admin',
              style: GoogleFonts.dmMono(
                fontSize: 11, color: AppColors.charcoal,
                letterSpacing: 0.1,
              ),
            ),
          ),
        // Auth
        if (!auth.isLoggedIn)
          TextButton(
            onPressed: () => context.go('/login'),
            child: Text('Ingresar',
              style: GoogleFonts.dmMono(
                fontSize: 11, color: AppColors.charcoal,
                letterSpacing: 0.1,
              ),
            ),
          ),
        if (auth.isLoggedIn)
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline,
                color: AppColors.charcoal, size: 20),
            onSelected: (v) {
              if (v == 'logout') context.read<AuthProvider>().logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'perfil',
                child: Text(auth.user?.nombre ?? 'Perfil',
                  style: GoogleFonts.dmMono(fontSize: 12),
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text('Cerrar sesión',
                  style: GoogleFonts.dmMono(fontSize: 12),
                ),
              ),
            ],
          ),
        const SizedBox(width: 8),
      ],
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
      child: Text(label.toUpperCase(),
        style: GoogleFonts.dmMono(
          fontSize: 11, color: AppColors.gray,
          letterSpacing: 0.12,
        ),
      ),
    );
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
        onExit:  (_) => setState(() => _hovered = false),
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
                  // Badge
                  if (p.color != null || !p.disponible)
                    Positioned(
                      top: 12, left: 12,
                      child: _Badge(
                        label: !p.disponible ? 'Agotado' : p.color!,
                        dark: !p.disponible,
                      ),
                    ),
                  // Quick add (visible en hover desktop)
                  // Offstage mantiene el widget montado para que el async
                  // no pierda el context cuando el mouse sale durante la espera
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Offstage(
                      offstage: !_hovered,
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
                  child: Text(p.titulo,
                    style: GoogleFonts.syne(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Text(p.precioFormateado,
                    style: GoogleFonts.dmMono(
                      fontSize: 12, color: AppColors.gray,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(p.categoria.toUpperCase(),
              style: GoogleFonts.dmMono(
                fontSize: 10, color: AppColors.stone,
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
      child: Text(label.toUpperCase(),
        style: GoogleFonts.dmMono(
          fontSize: 9, color: AppColors.cream, letterSpacing: 0.15,
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
        content: Text('Producto no disponible',
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

    if (ok) {
      messenger.showSnackBar(SnackBar(
        content: Text('✓ ${widget.producto.titulo} agregado',
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream),
        ),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      final error = carritoProvider.error ?? 'No se pudo agregar';
      messenger.showSnackBar(SnackBar(
        content: Text(error,
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
                  width: 12, height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: AppColors.cream,
                  ),
                )
              : Text(
                  widget.producto.disponible ? '+ AGREGAR AL CARRITO' : 'AGOTADO',
                  style: GoogleFonts.dmMono(
                    fontSize: 10, color: AppColors.cream, letterSpacing: 0.15,
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
              width: 16, height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 1.5, color: AppColors.cream,
              ),
            )
          : Text(label.toUpperCase(),
              style: GoogleFonts.dmMono(
                fontSize: 11, letterSpacing: 0.18,
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
      child: Text(label.toUpperCase(),
        style: GoogleFonts.dmMono(
          fontSize: 11, color: AppColors.charcoal, letterSpacing: 0.15,
        ),
      ),
    );
  }
}

// ─── AUTH FIELD ────────────────────────────────────────────
class AuthField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffix;
  final VoidCallback? onSubmit;
  final String? hint;

  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.onSubmit,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: GoogleFonts.dmMono(
            fontSize: 10, color: AppColors.gray, letterSpacing: 0.15,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
          style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.charcoal),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix != null
                ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix)
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Text(message,
        style: GoogleFonts.dmMono(fontSize: 11, color: Colors.red[700]),
      ),
    );
  }
}
