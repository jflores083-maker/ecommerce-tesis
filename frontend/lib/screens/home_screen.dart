import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_constants.dart';
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
                  // "638" gigante de fondo
                  Positioned(
                    top: -20, left: -10,
                    child: Text('638',
                      style: GoogleFonts.syne(
                        fontSize: 260, fontWeight: FontWeight.w800,
                        color: AppColors.sand, height: 1,
                      ),
                    ),
                  ),
                  // Contenido
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('COLECCIÓN OTOÑO 2025',
                        style: GoogleFonts.dmMono(
                          fontSize: 10, color: AppColors.stone,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 72, fontWeight: FontWeight.w300,
                            color: AppColors.ink, height: 1.0,
                          ),
                          children: const [
                            TextSpan(text: 'Vestí\nlo que\n'),
                            TextSpan(text: 'sos.',
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
                          fontSize: 12, color: AppColors.gray, height: 1.8,
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
              Text('COLECCIÓN OTOÑO 2025',
                style: GoogleFonts.dmMono(
                  fontSize: 10, color: AppColors.stone, letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 16),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 52, fontWeight: FontWeight.w300,
                    color: AppColors.ink, height: 1.0,
                  ),
                  children: const [
                    TextSpan(text: 'Vestí lo que\n'),
                    TextSpan(text: 'sos.',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: AppColors.stone,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Ropa urbana diseñada para los que se mueven en su propio ritmo.',
                style: GoogleFonts.dmMono(
                  fontSize: 12, color: AppColors.gray, height: 1.8,
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
            Text('FOTO DE CAMPAÑA',
              style: GoogleFonts.dmMono(
                fontSize: 10, color: AppColors.stone,
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
    final isMobile  = MediaQuery.of(context).size.width < 768;
    final featured  = productos.take(4).toList();

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64, vertical: isMobile ? 52 : 96,
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Destacados',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: isMobile ? 30 : 40, fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/catalogo'),
                child: Text('Ver todo →',
                  style: GoogleFonts.dmMono(
                    fontSize: 10, color: AppColors.stone,
                    letterSpacing: 0.18,
                  ),
                ),
              ),
            ],
          ),
          Divider(color: AppColors.sand, height: 40, thickness: 1),
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
    final isMobile  = MediaQuery.of(context).size.width < 768;
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
              Text('Categorías',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: isMobile ? 30 : 40, fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          Divider(color: AppColors.sand, height: 40, thickness: 1),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: isMobile ? 1 : 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 12,
            childAspectRatio: isMobile ? 16 / 7 : 4 / 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: AppCategorias.todas.map((cat) => _CategoryItem(
              label: cat,
              categoria: cat,
              imagenUrl: imagenParaCategoria(cat),
            )).toList(),
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
    required this.label, required this.categoria, this.imagenUrl,
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
            left: 20, right: 20, bottom: 20,
            child: Text(label,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 28, fontWeight: FontWeight.w300,
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
                    onPressed: () {},
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
                  onPressed: () {},
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
              fontSize: 48, fontWeight: FontWeight.w300,
              color: AppColors.cream, height: 1.1,
            ),
            children: const [
              TextSpan(text: 'Nueva '),
              TextSpan(text: 'drop',
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
        Text('Piezas limitadas que salen y no vuelven.',
          style: GoogleFonts.dmMono(
            fontSize: 12, color: AppColors.stone, height: 1.8,
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
      padding: EdgeInsets.all(isMobile ? 20 : 64),
      child: Column(
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: _footerContent(isMobile),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _footerContent(isMobile),
                ),
          const SizedBox(height: 32),
          const Divider(color: Color(0xFF2E2B28), height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('© 2025 638. Todos los derechos reservados.',
                style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.gray),
              ),
              Text('Buenos Aires, Argentina',
                style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.gray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _footerContent(bool isMobile) {
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('638',
            style: GoogleFonts.syne(
              fontSize: 22, fontWeight: FontWeight.w800,
              color: AppColors.cream, letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text('Ropa urbana de Buenos Aires\npara el mundo.',
            style: GoogleFonts.dmMono(
              fontSize: 12, color: AppColors.stone, height: 1.8,
            ),
          ),
        ],
      ),
      if (isMobile) const SizedBox(height: 32),
      _FooterCol('Tienda', ['Nueva colección', 'Remeras', 'Pantalones', 'Abrigos']),
      if (isMobile) const SizedBox(height: 24),
      _FooterCol('Ayuda', ['Guía de talles', 'Envíos', 'Devoluciones', 'Contacto']),
    ];
  }
}

class _FooterCol extends StatelessWidget {
  final String title;
  final List<String> items;
  const _FooterCol(this.title, this.items);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
          style: GoogleFonts.dmMono(
            fontSize: 10, color: AppColors.stone, letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(item,
            style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.gray),
          ),
        )),
      ],
    );
  }
}