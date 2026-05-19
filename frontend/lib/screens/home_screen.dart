import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../providers/config_provider.dart';
import '../providers/productos_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductosProvider>().cargarProductos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 768;

    return Scaffold(
      appBar: const AppNavBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── HERO ──
            isMobile ? _HeroMobile() : _HeroDesktop(),
            // ── DESTACADOS ──
            _FeaturedSection(),
            // ── CATEGORIAS ──
            _CategoriesSection(),
            // ── BANNER ──
            _Banner(),
            // ── FOOTER ──
            _Footer(),
          ],
        ),
      ),
    );
  }
}

// ─── HERO DESKTOP ──────────────────────────────────────────
class _HeroDesktop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 64,
      child: Row(
        children: [
          // Lado izquierdo
          Expanded(
            child: Container(
              color: AppColors.beige,
              padding: const EdgeInsets.fromLTRB(64, 64, 64, 80),
              child: Stack(
                children: [
                  // "Urbal" gigante de fondo
                  Positioned(
                    top: -20,
                    left: -10,
                    child: Text(
                      'Urbal',
                      style: GoogleFonts.syne(
                        fontSize: 150,
                        fontWeight: FontWeight.w800,
                        color: AppColors.sand,
                        height: 1,
                      ),
                    ),
                  ),
                  // Contenido
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'COLECCIÓN OTOÑO/INVIERNO 2026',
                        style: GoogleFonts.dmMono(
                          fontSize: 10,
                          color: AppColors.stone,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 72,
                            fontWeight: FontWeight.w300,
                            color: AppColors.ink,
                            height: 1.0,
                          ),
                          children: const [
                            TextSpan(text: 'Vestí\nlo que\n'),
                            TextSpan(
                              text: 'sos.',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppColors.stone,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Ropa urbana diseñada para los que se mueven\nen su propio ritmo.',
                        style: GoogleFonts.dmMono(
                          fontSize: 12,
                          color: AppColors.gray,
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(height: 48),
                      PrimaryButton(
                        label: 'Ver colección →',
                        onPressed: () => context.go('/catalogo'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Lado derecho — imagen hero del admin
          Expanded(
            child: _HeroImage(),
          ),
        ],
      ),
    );
  }
}

// ─── HERO MOBILE ───────────────────────────────────────────
class _HeroMobile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Imagen arriba
        SizedBox(
          height: MediaQuery.of(context).size.width * 0.9,
          child: _HeroImage(),
        ),
        // Texto abajo
        Container(
          color: AppColors.beige,
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 52),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'COLECCIÓN OTOÑO/INVIERNO 2026',
                style: GoogleFonts.dmMono(
                  fontSize: 10,
                  color: AppColors.stone,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 52,
                    fontWeight: FontWeight.w300,
                    color: AppColors.ink,
                    height: 1.0,
                  ),
                  children: const [
                    TextSpan(text: 'Vestí lo que\n'),
                    TextSpan(
                      text: 'sos.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: AppColors.stone,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Ropa urbana diseñada para los que se mueven en su propio ritmo.',
                style: GoogleFonts.dmMono(
                  fontSize: 12,
                  color: AppColors.gray,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Ver colección →',
                  onPressed: () => context.go('/catalogo'),
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── HERO IMAGE ────────────────────────────────────────────
class _HeroImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final heroUrl = context.watch<ConfigProvider>().heroImageUrl;
    if (heroUrl != null) {
      return Image.network(
        '${ApiService.serverUrl}$heroUrl',
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.charcoal,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 72, color: AppColors.stone.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text(
              'FOTO DE CAMPAÑA',
              style: GoogleFonts.dmMono(
                fontSize: 10,
                color: AppColors.stone,
                letterSpacing: 0.18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DESTACADOS ────────────────────────────────────────────
class _FeaturedSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final productos = context.watch<ProductosProvider>().productos;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final featured = productos.take(4).toList();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: isMobile ? 52 : 96,
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Destacados',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: isMobile ? 30 : 40,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/catalogo'),
                child: Text(
                  'Ver todo →',
                  style: GoogleFonts.dmMono(
                    fontSize: 10,
                    color: AppColors.stone,
                    letterSpacing: 0.18,
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.sand, height: 40, thickness: 1),
          const SizedBox(height: 16),
          if (featured.isEmpty)
            GridView.count(
              crossAxisCount: isMobile ? 2 : 4,
              crossAxisSpacing: isMobile ? 12 : 24,
              mainAxisSpacing: isMobile ? 20 : 28,
              childAspectRatio: isMobile ? 0.50 : 0.55,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(4, (_) => _PlaceholderCard()),
            )
          else
            GridView.count(
              crossAxisCount: isMobile ? 2 : 4,
              crossAxisSpacing: isMobile ? 12 : 24,
              mainAxisSpacing: isMobile ? 20 : 28,
              childAspectRatio: isMobile ? 0.50 : 0.55,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: featured.map((p) => ProductCard(producto: p)).toList(),
            ),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Container(color: AppColors.sand),
        ),
        const SizedBox(height: 12),
        Container(height: 12, width: 120, color: AppColors.sand),
        const SizedBox(height: 6),
        Container(height: 10, width: 60, color: AppColors.sand),
      ],
    );
  }
}

// ─── CATEGORÍAS ────────────────────────────────────────────
class _CategoriesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final productos = context.watch<ProductosProvider>().productos;

    // Para cada categoría, buscar el primer producto con imagen
    String? imagenParaCategoria(String cat) {
      try {
        return productos
            .firstWhere((p) =>
                p.categoria.toLowerCase() == cat.toLowerCase() &&
                p.imagenPrincipalUrl != null)
            .imagenPrincipalUrl;
      } catch (_) {
        return null;
      }
    }

    return Container(
      color: AppColors.beige,
      padding: EdgeInsets.all(isMobile ? 20 : 64),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Categorías',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: isMobile ? 30 : 40,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.sand, height: 40, thickness: 1),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: isMobile ? 1 : 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 12,
            childAspectRatio: isMobile ? 16 / 7 : 4 / 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: context.read<ConfigProvider>().categorias
                .map((cat) => _CategoryItem(
                      label: cat,
                      categoria: cat,
                      imagenUrl: imagenParaCategoria(cat),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final String categoria;
  final String? imagenUrl;
  const _CategoryItem({
    required this.label,
    required this.categoria,
    this.imagenUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/catalogo?categoria=$categoria'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo: imagen del producto o color sólido
          if (imagenUrl != null)
            Image.network(
              '${ApiService.serverUrl}$imagenUrl',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppColors.sand),
            )
          else
            Container(color: AppColors.sand),

          // Overlay oscuro para legibilidad
          if (imagenUrl != null)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
            ),

          // Nombre de la categoría
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Text(
              label,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: imagenUrl != null ? AppColors.cream : AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BANNER ────────────────────────────────────────────────
class _Banner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: AppColors.ink,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: isMobile ? 56 : 80,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _bannerText(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: 'Ver últimos drops →',
                    onPressed: () => context.go('/drops'),
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _bannerText(),
                PrimaryButton(
                  label: 'Ver últimos drops →',
                  onPressed: () => context.go('/drops'),
                ),
              ],
            ),
    );
  }

  Widget _bannerText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.cormorantGaramond(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: AppColors.cream,
              height: 1.1,
            ),
            children: const [
              TextSpan(text: 'Nueva '),
              TextSpan(
                text: 'drop',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.accent,
                ),
              ),
              TextSpan(text: '\ncada viernes.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Piezas limitadas que salen y no vuelven.',
          style: GoogleFonts.dmMono(
            fontSize: 12,
            color: AppColors.stone,
            height: 1.8,
          ),
        ),
      ],
    );
  }
}

// ─── FOOTER ────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      color: AppColors.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Contenido principal ──────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
              isMobile ? 24 : 64,
              isMobile ? 48 : 72,
              isMobile ? 24 : 64,
              isMobile ? 40 : 64,
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FooterBrand(),
                      const SizedBox(height: 40),
                      const _FooterCol(
                        title: 'Tienda',
                        items: [
                          _FooterLink('Nueva colección', '/catalogo'),
                          _FooterLink('Remeras', '/catalogo?categoria=Remeras'),
                          _FooterLink(
                              'Pantalones', '/catalogo?categoria=Pantalones'),
                          _FooterLink('Abrigos', '/catalogo?categoria=Abrigos'),
                          _FooterLink('Ver todo', '/catalogo'),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const _FooterCol(
                        title: 'Nosotros',
                        items: [
                          _FooterLink('Acerca de', '/acerca-de'),
                          _FooterLink('Colección', '/catalogo'),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _FooterContact(),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _FooterBrand()),
                      const Expanded(
                        flex: 2,
                        child: _FooterCol(
                          title: 'Tienda',
                          items: [
                            _FooterLink('Nueva colección', '/catalogo'),
                            _FooterLink(
                                'Remeras', '/catalogo?categoria=Remeras'),
                            _FooterLink(
                                'Pantalones', '/catalogo?categoria=Pantalones'),
                            _FooterLink(
                                'Abrigos', '/catalogo?categoria=Abrigos'),
                            _FooterLink('Ver todo', '/catalogo'),
                          ],
                        ),
                      ),
                      const Expanded(
                        flex: 2,
                        child: _FooterCol(
                          title: 'Nosotros',
                          items: [
                            _FooterLink('Acerca de', '/acerca-de'),
                            _FooterLink('Colección', '/catalogo'),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: _FooterContact()),
                    ],
                  ),
          ),

          // ── Divider ──────────────────────────────────────
          const Divider(color: Color(0xFF2E2B28), height: 1),

          // ── Bottom bar ───────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 24 : 64,
              vertical: 20,
            ),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '© 2025 Urbal. Todos los derechos reservados.',
                        style: GoogleFonts.dmMono(
                            fontSize: 10, color: AppColors.gray),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Buenos Aires, Argentina',
                        style: GoogleFonts.dmMono(
                            fontSize: 10, color: AppColors.gray),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '© 2025 Urbal. Todos los derechos reservados.',
                        style: GoogleFonts.dmMono(
                            fontSize: 10, color: AppColors.gray),
                      ),
                      Text(
                        'Hecho con cuidado en Buenos Aires.',
                        style: GoogleFonts.dmMono(
                            fontSize: 10, color: AppColors.gray),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Urbal',
          style: GoogleFonts.syne(
            fontSize: 48,
            fontWeight: FontWeight.w800,
            color: AppColors.cream,
            letterSpacing: -1,
            height: 1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Ropa urbana de Buenos Aires\npara el mundo.',
          style: GoogleFonts.dmMono(
            fontSize: 12,
            color: AppColors.stone,
            height: 2.0,
          ),
        ),
        const SizedBox(height: 24),
        Container(height: 1, width: 40, color: AppColors.accent),
        const SizedBox(height: 24),
        Text(
          'Diseño propio. Producción local.\nEdiciones limitadas.',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 18,
            fontWeight: FontWeight.w300,
            color: const Color(0xFF7A7570),
            height: 1.6,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _FooterLink {
  final String label;
  final String route;
  const _FooterLink(this.label, this.route);
}

class _FooterCol extends StatelessWidget {
  final String title;
  final List<_FooterLink> items;
  const _FooterCol({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.dmMono(
            fontSize: 10,
            color: AppColors.accent,
            letterSpacing: 0.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        ...items.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => context.go(link.route),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    link.label,
                    style: GoogleFonts.dmMono(
                      fontSize: 13,
                      color: AppColors.stone,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

class _FooterContact extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final telefono = config.contactoTelefono;
    final email = config.contactoEmail;
    final direccion = config.contactoDireccion;
    final horario = config.contactoHorario;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CONTACTO',
          style: GoogleFonts.dmMono(
            fontSize: 10,
            color: AppColors.accent,
            letterSpacing: 0.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        if (direccion.isNotEmpty) ...[
          Text(
            direccion,
            style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.stone),
          ),
          const SizedBox(height: 12),
        ],
        if (email.isNotEmpty) ...[
          Text(
            email,
            style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.stone),
          ),
          const SizedBox(height: 12),
        ],
        if (horario.isNotEmpty) ...[
          Text(
            horario,
            style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.gray),
          ),
          const SizedBox(height: 24),
        ] else
          const SizedBox(height: 24),
        Row(
          children: [
            const _SocialChip(label: 'IG'),
            const SizedBox(width: 8),
            const _SocialChip(label: 'TK'),
            if (telefono.isNotEmpty) ...[
              const SizedBox(width: 8),
              _SocialChip(
                label: 'WhatsApp',
                icon: FontAwesomeIcons.whatsapp,
                onTap: () async {
                  final numero = telefono.replaceAll(RegExp(r'[^\d]'), '');
                  try {
                    await launchUrl(
                      Uri.parse('https://wa.me/$numero'),
                      webOnlyWindowName: '_blank',
                    );
                  } catch (_) {}
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SocialChip extends StatefulWidget {
  final String label;
  final FaIconData? icon;
  final VoidCallback? onTap;
  const _SocialChip({required this.label, this.icon, this.onTap});

  @override
  State<_SocialChip> createState() => _SocialChipState();
}

class _SocialChipState extends State<_SocialChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = _hovered ? AppColors.accent : AppColors.gray;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(
              color: _hovered ? AppColors.accent : const Color(0xFF3A3632),
            ),
            color: _hovered
                ? AppColors.accent.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: widget.icon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(widget.icon!, size: 11, color: color),
                    const SizedBox(width: 6),
                    Text(
                      widget.label,
                      style: GoogleFonts.dmMono(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1),
                    ),
                  ],
                )
              : Text(
                  widget.label,
                  style: GoogleFonts.dmMono(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1),
                ),
        ),
      ),
    );
  }
}
