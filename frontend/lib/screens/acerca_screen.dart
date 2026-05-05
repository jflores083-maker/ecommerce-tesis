import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AcercaScreen extends StatelessWidget {
  const AcercaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: const AppNavBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HERO ──────────────────────────────────────────────
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 96,
                vertical: isMobile ? 56 : 96,
              ),
              child: isMobile
                  ? _HeroContent(config: config)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: _HeroContent(config: config)),
                        const SizedBox(width: 80),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Urbal',
                            style: GoogleFonts.syne(
                              fontSize: 110,
                              fontWeight: FontWeight.w800,
                              color: AppColors.sand,
                              height: 0.9,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),

            // ── SEPARADOR ─────────────────────────────────────────
            Container(height: 1, color: AppColors.sand),

            // ── VALORES ───────────────────────────────────────────
            Container(
              color: AppColors.beige,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 96,
                vertical: isMobile ? 48 : 80,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LO QUE NOS DEFINE',
                    style: GoogleFonts.dmMono(
                      fontSize: 10,
                      color: AppColors.stone,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 32),
                  isMobile
                      ? Column(
                          children: _valores()
                              .map((v) => Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: _ValorItem(
                                        titulo: v.$1, descripcion: v.$2),
                                  ))
                              .toList(),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _valores()
                              .map((v) => Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 40),
                                      child: _ValorItem(
                                          titulo: v.$1, descripcion: v.$2),
                                    ),
                                  ))
                              .toList(),
                        ),
                ],
              ),
            ),

            // ── FOOTER ────────────────────────────────────────────
            Container(
              color: AppColors.ink,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 96,
                vertical: 24,
              ),
              child: Text(
                '© 2025 Urbal. Buenos Aires, Argentina.',
                style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.gray),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<(String, String)> _valores() => [
        (
          'Diseño propio',
          'Cada pieza nace de una idea nuestra. Sin fórmulas, sin copias.'
        ),
        (
          'Producción local',
          'Fabricamos en Buenos Aires con materiales seleccionados.'
        ),
        (
          'Ediciones limitadas',
          'Lo que lanzamos no se repite. Cuando se acaba, se acaba.'
        ),
      ];
}

class _HeroContent extends StatelessWidget {
  final ConfigProvider config;
  const _HeroContent({required this.config});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SOBRE NOSOTROS',
          style: GoogleFonts.dmMono(
            fontSize: 10,
            color: AppColors.stone,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          config.acercaTitulo,
          style: GoogleFonts.syne(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 24),
        Container(height: 1, width: 48, color: AppColors.stone),
        const SizedBox(height: 24),
        Text(
          'Ropa urbana de Buenos Aires para el mundo.',
          style: GoogleFonts.dmMono(
            fontSize: 13,
            color: AppColors.charcoal,
            height: 1.8,
          ),
        ),
        if (config.acercaDescripcion.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text(
            config.acercaDescripcion,
            style: GoogleFonts.dmMono(
              fontSize: 13,
              color: AppColors.charcoal,
              height: 2.0,
            ),
          ),
        ],
      ],
    );
  }
}

class _ValorItem extends StatelessWidget {
  final String titulo;
  final String descripcion;
  const _ValorItem({required this.titulo, required this.descripcion});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: GoogleFonts.syne(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          descripcion,
          style: GoogleFonts.dmMono(
            fontSize: 11,
            color: AppColors.charcoal,
            height: 1.8,
          ),
        ),
      ],
    );
  }
}
