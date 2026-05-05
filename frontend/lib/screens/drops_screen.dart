import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/drops_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class DropsScreen extends StatefulWidget {
  const DropsScreen({super.key});

  @override
  State<DropsScreen> createState() => _DropsScreenState();
}

class _DropsScreenState extends State<DropsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DropsProvider>().cargarDrops();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final provider = context.watch<DropsProvider>();

    return Scaffold(
      appBar: const AppNavBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              color: AppColors.ink,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 80,
                vertical: 56,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DROPS',
                    style: GoogleFonts.syne(
                      fontSize: isMobile ? 52 : 80,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cream,
                      height: 0.9,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lanzamientos exclusivos de Urbal.',
                    style: GoogleFonts.dmMono(
                        fontSize: 12, color: AppColors.stone),
                  ),
                ],
              ),
            ),

            // ── Grid ──
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 20 : 80,
                vertical: 48,
              ),
              child: provider.cargando
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.charcoal))
                  : provider.drops.isEmpty
                      ? Center(
                          child: Text(
                            'No hay drops todavía.',
                            style: GoogleFonts.dmMono(
                                fontSize: 13, color: AppColors.stone),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isMobile ? 1 : 3,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: provider.drops.length,
                          itemBuilder: (_, i) =>
                              _DropCard(drop: provider.drops[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropCard extends StatefulWidget {
  final Drop drop;
  const _DropCard({required this.drop});

  @override
  State<_DropCard> createState() => _DropCardState();
}

class _DropCardState extends State<_DropCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final drop = widget.drop;
    final mes = _mesAbreviado(drop.fechaCreacion.month);
    final anio = drop.fechaCreacion.year;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/drops/${drop.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  drop.imagenUrl != null
                      ? Image.network(
                          '${ApiService.serverUrl}${drop.imagenUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                  // Overlay hover
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: _hovered
                        ? AppColors.ink.withValues(alpha: 0.35)
                        : Colors.transparent,
                  ),
                  // Badge fecha
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      color: AppColors.ink,
                      child: Text(
                        '$mes $anio',
                        style: GoogleFonts.dmMono(
                          fontSize: 9,
                          color: AppColors.cream,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
                  ),
                  // Badge cantidad
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      color: AppColors.accent,
                      child: Text(
                        '${drop.totalProductos} PIEZAS',
                        style: GoogleFonts.dmMono(
                          fontSize: 9,
                          color: AppColors.cream,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: AppColors.beige,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      drop.nombre,
                      style: GoogleFonts.syne(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward,
                      size: 16, color: AppColors.charcoal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.sand,
      child: const Center(
        child: Icon(Icons.bolt_outlined, size: 48, color: AppColors.stone),
      ),
    );
  }

  String _mesAbreviado(int mes) {
    const meses = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGO',
      'SEP',
      'OCT',
      'NOV',
      'DIC'
    ];
    return meses[mes - 1];
  }
}
