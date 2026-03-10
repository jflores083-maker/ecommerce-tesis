import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/productos_provider.dart';
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
      backgroundColor: AppColors.cream,
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
          // Lado derecho (placeholder imagen campaña)
          Expanded(
            child: Container(
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
            ),
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
        Container(
          height: MediaQuery.of(context).size.width * 0.9,
          color: AppColors.charcoal,
          child: Center(
            child: Icon(Icons.shopping_bag_outlined,
              size: 60, color: AppColors.stone.withOpacity(0.2)),
          ),
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
                  fontSize: isMobile ? 30 : 40, fontWeight: FontWeight.w300,
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
              childAspectRatio: 0.65,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(4, (_) => _PlaceholderCard()),
            )
          else
            GridView.count(
              crossAxisCount: isMobile ? 2 : 4,
              crossAxisSpacing: isMobile ? 12 : 24,
              mainAxisSpacing: isMobile ? 20 : 28,
              childAspectRatio: 0.65,
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
  static const _cats = [
    {'label': 'Remeras', 'count': '24 productos', 'cat': 'Remeras'},
    {'label': 'Pantalones', 'count': '18 productos', 'cat': 'Pantalones'},
    {'label': 'Abrigos', 'count': '12 productos', 'cat': 'Abrigos'},
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

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
                  fontSize: isMobile ? 30 : 40, fontWeight: FontWeight.w300,
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
            children: _cats.map((c) => _CategoryItem(
              label: c['label']!,
              count: c['count']!,
              categoria: c['cat']!,
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final String count;
  final String categoria;
  const _CategoryItem({
    required this.label, required this.count, required this.categoria,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/catalogo?categoria=$categoria'),
      child: Container(
        color: AppColors.sand,
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28, fontWeight: FontWeight.w300, color: AppColors.ink,
                ),
              ),
              Text(count,
                style: GoogleFonts.dmMono(
                  fontSize: 10, color: AppColors.gray, letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
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