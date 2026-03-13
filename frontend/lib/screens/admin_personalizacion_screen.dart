import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  bool _guardando = false;

  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _contactoEmailCtrl;
  late final TextEditingController _contactoTelefonoCtrl;
  late final TextEditingController _contactoDireccionCtrl;
  late final TextEditingController _contactoHorarioCtrl;
  bool _inicializado = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _contactoEmailCtrl.dispose();
    _contactoTelefonoCtrl.dispose();
    _contactoDireccionCtrl.dispose();
    _contactoHorarioCtrl.dispose();
    super.dispose();
  }

  void _inicializarAcerca(ConfigProvider config) {
    if (_inicializado) return;
    _tituloCtrl            = TextEditingController(text: config.acercaTitulo);
    _descripcionCtrl       = TextEditingController(text: config.acercaDescripcion);
    _contactoEmailCtrl     = TextEditingController(text: config.contactoEmail);
    _contactoTelefonoCtrl  = TextEditingController(text: config.contactoTelefono);
    _contactoDireccionCtrl = TextEditingController(text: config.contactoDireccion);
    _contactoHorarioCtrl   = TextEditingController(text: config.contactoHorario);
    _inicializado = true;
  }

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

  Future<void> _guardarYVolver() async {
    setState(() => _guardando = true);
    final config = context.read<ConfigProvider>();
    final okAcerca = await config.guardarAcerca(
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
    );
    final okContacto = await config.guardarContacto(
      email:     _contactoEmailCtrl.text.trim(),
      telefono:  _contactoTelefonoCtrl.text.trim(),
      direccion: _contactoDireccionCtrl.text.trim(),
      horario:   _contactoHorarioCtrl.text.trim(),
    );
    if (mounted) {
      setState(() => _guardando = false);
      if (okAcerca && okContacto) {
        context.go('/admin');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar',
            style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream),
          ),
          backgroundColor: AppColors.charcoal,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config   = context.watch<ConfigProvider>();
    _inicializarAcerca(config);
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

                // ── Acerca de ─────────────────────────────────
                Text('PÁGINA "ACERCA DE"',
                  style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.gray, letterSpacing: 0.15),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tituloCtrl,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    labelStyle: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sand)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sand)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.ink)),
                    filled: true,
                    fillColor: AppColors.beige,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: GoogleFonts.cormorantGaramond(fontSize: 20, color: AppColors.ink),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descripcionCtrl,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    alignLabelWithHint: true,
                    labelStyle: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
                    border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sand)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sand)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.ink)),
                    filled: true,
                    fillColor: AppColors.beige,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.charcoal, height: 1.8),
                ),
                const SizedBox(height: 8),
                Text('Este texto aparece en la página "Acerca de" de la tienda.',
                  style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.stone),
                ),
                const SizedBox(height: 48),

                // ── Contacto ──────────────────────────────────
                Text('DATOS DE CONTACTO',
                  style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.gray, letterSpacing: 0.15),
                ),
                const SizedBox(height: 8),
                Text('Se muestran en el pie de página.',
                  style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.stone),
                ),
                const SizedBox(height: 12),
                _campoTexto('Email', _contactoEmailCtrl, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _campoTexto('Teléfono / WhatsApp (ej: +5491112345678)', _contactoTelefonoCtrl, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                _campoTexto('Dirección', _contactoDireccionCtrl),
                const SizedBox(height: 12),
                _campoTexto('Horario (ej: Lun – Vie, 10 a 18 hs.)', _contactoHorarioCtrl),
                const SizedBox(height: 48),

                // ── Guardar ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardarYVolver,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.cream,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: const RoundedRectangleBorder(),
                      elevation: 0,
                    ),
                    child: _guardando
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream))
                        : Text('Guardar y volver',
                            style: GoogleFonts.dmMono(fontSize: 12, letterSpacing: 0.1),
                          ),
                  ),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoTexto(String label, TextEditingController ctrl, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sand)),
        enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sand)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.ink)),
        filled: true,
        fillColor: AppColors.beige,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.ink),
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
