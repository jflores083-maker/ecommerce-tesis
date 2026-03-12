import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AdminPersonalizacionScreen extends StatefulWidget {
  const AdminPersonalizacionScreen({super.key});

  @override
  State<AdminPersonalizacionScreen> createState() => _AdminPersonalizacionScreenState();
}

class _AdminPersonalizacionScreenState extends State<AdminPersonalizacionScreen> {
  Uint8List? _previewBytes;
  bool _subiendo = false;

  Future<void> _pickHero() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _previewBytes = bytes;
      _subiendo = true;
    });

    final ok = await context.read<ConfigProvider>().subirHero(picked);

    if (mounted) {
      setState(() => _subiendo = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          ok ? '✓ Imagen del inicio actualizada' : 'Error al subir la imagen',
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream),
        ),
        backgroundColor: ok ? AppColors.ink : AppColors.charcoal,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final config   = context.watch<ConfigProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: const AppNavBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 0, vertical: 48),
        child: Center(
          child: SizedBox(
            width: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Personalización',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 40, fontWeight: FontWeight.w300, color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Cambiá la imagen y los colores de la tienda.',
                  style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
                ),
                const SizedBox(height: 40),

                // ── Imagen del inicio ─────────────────
                Text('IMAGEN DEL INICIO',
                  style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.gray, letterSpacing: 0.15),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _subiendo ? null : _pickHero,
                  child: Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.sand),
                      color: AppColors.beige,
                    ),
                    child: _subiendo
                        ? const Center(child: CircularProgressIndicator(color: AppColors.charcoal))
                        : _previewBytes != null
                            ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                            : config.heroImageUrl != null
                                ? Image.network(
                                    '${ApiService.serverUrl}${config.heroImageUrl}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _heroPlaceholder(),
                                  )
                                : _heroPlaceholder(),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Tocá para cambiar la imagen. Se verá en la sección principal del inicio.',
                  style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.stone),
                ),
                const SizedBox(height: 40),

                // ── Tema de colores ───────────────────
                Text('TEMA DE COLORES',
                  style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.gray, letterSpacing: 0.15),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(AppPaleta.todas.length, (i) {
                    final paleta   = AppPaleta.todas[i];
                    final selected = config.temaIndex == i;
                    return GestureDetector(
                      onTap: () => config.setTema(i),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: paleta.fondo,
                              border: Border.all(
                                color: selected ? AppColors.ink : AppColors.sand,
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Expanded(child: Container(color: paleta.fondo)),
                                Container(height: 12, color: paleta.secundario),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(paleta.nombre,
                            style: GoogleFonts.dmMono(
                              fontSize: 9,
                              color: selected ? AppColors.ink : AppColors.stone,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.stone),
        const SizedBox(height: 8),
        Text('Seleccionar imagen del inicio',
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
        ),
      ],
    );
  }
}
