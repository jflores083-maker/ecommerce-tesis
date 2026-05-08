import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/favoritos_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritosProvider>().cargarFavoritos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FavoritosProvider>();

    return Scaffold(
      appBar: const AppNavBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            child: Text(
              'Mis favoritos',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 40,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
                color: AppColors.ink,
              ),
            ),
          ),
          if (provider.loading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.charcoal),
              ),
            )
          else if (provider.error != null)
            Expanded(child: Center(child: ErrorMsg(provider.error!)))
          else if (provider.favoritos.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border,
                        size: 64, color: AppColors.stone.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      'No tenés favoritos guardados',
                      style: GoogleFonts.dmMono(
                        fontSize: 13,
                        color: AppColors.stone,
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlineBtn(
                      label: 'Ver colección',
                      onPressed: () => context.go('/catalogo'),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.65,
                ),
                itemCount: provider.favoritos.length,
                itemBuilder: (context, index) {
                  final fav = provider.favoritos[index];
                  return _FavoritoCard(fav: fav);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FavoritoCard extends StatelessWidget {
  final Favorito fav;
  const _FavoritoCard({required this.fav});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/producto/${fav.productoId}'),
      child: Container(
        color: AppColors.beige,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              child: Stack(
                children: [
                  // Imagen del producto
                  fav.imagenPrincipal != null
                      ? Image.network(
                          '${ApiService.serverUrl}${fav.imagenPrincipal}',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                  // Botón eliminar favorito
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => context
                          .read<FavoritosProvider>()
                          .toggleFavorito(fav.productoId),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        color: AppColors.cream,
                        child: const Icon(
                          Icons.favorite,
                          size: 18,
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fav.titulo,
                    style: GoogleFonts.dmMono(
                      fontSize: 11,
                      color: AppColors.charcoal,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fav.precioFormateado,
                    style: GoogleFonts.syne(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
                    ),
                  ),
                  if (fav.stock <= 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'AGOTADO',
                        style: GoogleFonts.dmMono(
                          fontSize: 9,
                          color: AppColors.stone,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.sand,
        child: Center(
          child: Icon(Icons.shopping_bag_outlined,
              size: 48, color: AppColors.stone.withOpacity(0.2)),
        ),
      );
}
