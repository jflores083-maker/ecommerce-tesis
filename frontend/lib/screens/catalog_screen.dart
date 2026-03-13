import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_constants.dart';
import '../providers/productos_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class CatalogScreen extends StatefulWidget {
  final String? categoriaInicial;
  const CatalogScreen({super.key, this.categoriaInicial});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _categorias = ['Todos', ...AppCategorias.todas];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductosProvider>().cargarProductos(
        categoria: widget.categoriaInicial,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductosProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;
    final px = isMobile ? 20.0 : 64.0;

    return Scaffold(
      appBar: const AppNavBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(px, 40, px, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('Colección',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: isMobile ? 36 : 48,
                    fontWeight: FontWeight.w300,
                    color: AppColors.ink,
                  ),
                ),
                Text('${provider.productos.length} productos',
                  style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
                ),
              ],
            ),
          ),

          // Toolbar filtros
          Container(
            margin: EdgeInsets.fromLTRB(px, 20, px, 0),
            padding: const EdgeInsets.only(bottom: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.sand)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._categorias.map((cat) => _FilterChip(
                    label: cat,
                    active: (provider.categoriaActiva.isEmpty && cat == 'Todos') ||
                            provider.categoriaActiva == cat,
                    onTap: () => provider.cargarProductos(
                      categoria: cat == 'Todos' ? null : cat,
                    ),
                  )),
                ],
              ),
            ),
          ),

          // Grid
          Expanded(
            child: provider.loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.charcoal),
                  )
                : provider.error != null
                    ? Center(child: ErrorMsg(provider.error!))
                    : provider.productos.isEmpty
                        ? Center(
                            child: Text('No hay productos en esta categoría.',
                              style: GoogleFonts.dmMono(
                                fontSize: 12, color: AppColors.stone,
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.fromLTRB(px, 32, px, 80),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isMobile ? 2 : 4,
                              crossAxisSpacing: isMobile ? 12 : 24,
                              mainAxisSpacing: isMobile ? 20 : 32,
                              childAspectRatio: isMobile ? 0.50 : 0.55,
                            ),
                            itemCount: provider.productos.length,
                            itemBuilder: (_, i) =>
                                ProductCard(producto: provider.productos[i]),
                          ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label, required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: active ? AppColors.charcoal : AppColors.sand,
          ),
          color: active ? AppColors.beige : Colors.transparent,
        ),
        child: Text(label.toUpperCase(),
          style: GoogleFonts.dmMono(
            fontSize: 10,
            color: active ? AppColors.ink : AppColors.gray,
            letterSpacing: 0.12,
          ),
        ),
      ),
    );
  }
}
