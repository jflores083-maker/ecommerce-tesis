import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/productos_provider.dart';
import '../providers/carrito_provider.dart';
import '../providers/auth_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class DetailScreen extends StatefulWidget {
  final int productoId;
  const DetailScreen({super.key, required this.productoId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  String? _talleSeleccionado;
  bool _agregando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductosProvider>().cargarDetalle(widget.productoId);
    });
  }

  Future<void> _agregarAlCarrito(Producto p) async {
    if (_talleSeleccionado == null) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Seleccioná un talle',
            style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream)),
        backgroundColor: AppColors.charcoal,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    // Si no está logueado, redirigir al login
    if (!context.read<AuthProvider>().isLoggedIn) {
      context.go('/login');
      return;
    }

    setState(() => _agregando = true);

    final ok = await context.read<CarritoProvider>().agregar(
          productoId: p.id,
          talle: _talleSeleccionado!,
        );

    setState(() => _agregando = false);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ ${p.titulo} agregado al carrito',
            style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream)),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'VER CARRITO',
          textColor: AppColors.accent,
          onPressed: () => context.go('/carrito'),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductosProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: const AppNavBar(),
      body: provider.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.charcoal))
          : provider.error != null
              ? Center(child: ErrorMsg(provider.error!))
              : provider.productoDetalle == null
                  ? const SizedBox()
                  : isMobile
                      ? _MobileLayout(
                          producto: provider.productoDetalle!,
                          talleSeleccionado: _talleSeleccionado,
                          onTalleSelected: (t) =>
                              setState(() => _talleSeleccionado = t),
                          agregando: _agregando,
                          onAgregar: _agregarAlCarrito,
                        )
                      : _DesktopLayout(
                          producto: provider.productoDetalle!,
                          talleSeleccionado: _talleSeleccionado,
                          onTalleSelected: (t) =>
                              setState(() => _talleSeleccionado = t),
                          agregando: _agregando,
                          onAgregar: _agregarAlCarrito,
                        ),
    );
  }
}

// ─── DESKTOP ───────────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final Producto producto;
  final String? talleSeleccionado;
  final ValueChanged<String> onTalleSelected;
  final bool agregando;
  final Function(Producto) onAgregar;

  const _DesktopLayout({
    required this.producto,
    required this.talleSeleccionado,
    required this.onTalleSelected,
    required this.agregando,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Galería sticky
        Expanded(
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 64,
            child: _DetailImage(producto: producto),
          ),
        ),
        // Info
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(56, 64, 56, 80),
            child: _ProductInfo(
              producto: producto,
              talleSeleccionado: talleSeleccionado,
              onTalleSelected: onTalleSelected,
              agregando: agregando,
              onAgregar: onAgregar,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── MOBILE ────────────────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final Producto producto;
  final String? talleSeleccionado;
  final ValueChanged<String> onTalleSelected;
  final bool agregando;
  final Function(Producto) onAgregar;

  const _MobileLayout({
    required this.producto,
    required this.talleSeleccionado,
    required this.onTalleSelected,
    required this.agregando,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Imagen
          SizedBox(
            height: MediaQuery.of(context).size.width * 0.85,
            child: _DetailImage(producto: producto),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 48),
            child: _ProductInfo(
              producto: producto,
              talleSeleccionado: talleSeleccionado,
              onTalleSelected: onTalleSelected,
              agregando: agregando,
              onAgregar: onAgregar,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── INFO COMPARTIDO ───────────────────────────────────────
class _ProductInfo extends StatelessWidget {
  final Producto producto;
  final String? talleSeleccionado;
  final ValueChanged<String> onTalleSelected;
  final bool agregando;
  final Function(Producto) onAgregar;

  const _ProductInfo({
    required this.producto,
    required this.talleSeleccionado,
    required this.onTalleSelected,
    required this.agregando,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    final p = producto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb
        Row(
          children: [
            GestureDetector(
              onTap: () => context.go('/'),
              child: Text('Inicio',
                  style: GoogleFonts.dmMono(
                    fontSize: 10,
                    color: AppColors.stone,
                    letterSpacing: 0.12,
                  )),
            ),
            Text(' › ',
                style: GoogleFonts.dmMono(
                  fontSize: 10,
                  color: AppColors.stone.withOpacity(0.4),
                )),
            GestureDetector(
              onTap: () => context.go('/catalogo'),
              child: Text('Colección',
                  style: GoogleFonts.dmMono(
                    fontSize: 10,
                    color: AppColors.stone,
                    letterSpacing: 0.12,
                  )),
            ),
            Text(' › ',
                style: GoogleFonts.dmMono(
                  fontSize: 10,
                  color: AppColors.stone.withOpacity(0.4),
                )),
            Flexible(
              child: Text(p.titulo,
                  style: GoogleFonts.dmMono(
                    fontSize: 10,
                    color: AppColors.charcoal,
                    letterSpacing: 0.12,
                  ),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Categoría
        Text(
          '${p.categoria.toUpperCase()} / TEMPORADA 2025',
          style: GoogleFonts.dmMono(
            fontSize: 10,
            color: AppColors.accent,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),

        // Nombre
        Text(
          p.titulo,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 48,
            fontWeight: FontWeight.w300,
            color: AppColors.ink,
            height: 1.05,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 8),

        // Precio
        Text(
          p.precioFormateado,
          style: GoogleFonts.syne(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: AppColors.charcoal,
          ),
        ),
        const Divider(color: AppColors.sand, height: 48, thickness: 1),

        // Talles
        Text(
          'TALLE',
          style: GoogleFonts.dmMono(
            fontSize: 10,
            color: AppColors.gray,
            letterSpacing: 0.15,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: p.talles
              .map((t) => _TalleBtn(
                    talle: t,
                    selected: talleSeleccionado == t,
                    onTap: () => onTalleSelected(t),
                  ))
              .toList(),
        ),
        const SizedBox(height: 32),

        // Botones
        PrimaryButton(
          label: 'Agregar al carrito',
          onPressed: () => onAgregar(p),
          loading: agregando,
          fullWidth: true,
        ),
        const SizedBox(height: 12),
        OutlineBtn(
          label: '♡  Guardar en favoritos',
          onPressed: () {},
        ),
        const SizedBox(height: 32),

        // Acordeón
        _Accordion('Descripción',
            p.descripcion.isNotEmpty ? p.descripcion : 'Sin descripción.'),
        _Accordion('Materiales', 'Consultar en el detalle del producto.'),
        _Accordion('Envío & devoluciones',
            'Envío gratis en compras mayores a \$60.000. Entrega en 3-5 días hábiles.'),
      ],
    );
  }
}

class _TalleBtn extends StatelessWidget {
  final String talle;
  final bool selected;
  final VoidCallback onTap;
  const _TalleBtn(
      {required this.talle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.sand,
          ),
        ),
        child: Center(
          child: Text(
            talle,
            style: GoogleFonts.dmMono(
              fontSize: 11,
              color: selected ? AppColors.cream : AppColors.gray,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailImage extends StatelessWidget {
  final Producto producto;
  const _DetailImage({required this.producto});

  @override
  Widget build(BuildContext context) {
    final url = producto.imagenPrincipalUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        '${ApiService.serverUrl}$url',
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : Container(color: AppColors.beige),
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        color: AppColors.beige,
        child: Center(
          child: Icon(Icons.shopping_bag_outlined,
              size: 72, color: AppColors.stone.withOpacity(0.2)),
        ),
      );
}

class _Accordion extends StatefulWidget {
  final String title;
  final String content;
  const _Accordion(this.title, this.content);

  @override
  State<_Accordion> createState() => _AccordionState();
}

class _AccordionState extends State<_Accordion> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: AppColors.sand, height: 1, thickness: 1),
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title.toUpperCase(),
                  style: GoogleFonts.dmMono(
                    fontSize: 11,
                    color: AppColors.charcoal,
                    letterSpacing: 0.12,
                  ),
                ),
                AnimatedRotation(
                  turns: _open ? 0.125 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.add,
                      size: 18, color: AppColors.charcoal),
                ),
              ],
            ),
          ),
        ),
        if (_open) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              widget.content,
              style: GoogleFonts.dmMono(
                fontSize: 12,
                color: AppColors.charcoal,
                height: 1.8,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
