import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _telefonoCtrl;
  final TextEditingController _passActualCtrl = TextEditingController();
  final TextEditingController _passNuevaCtrl  = TextEditingController();

  bool _guardando = false;
  bool _cambiarPass = false;
  bool _obscuraActual = true;
  bool _obscuraNueva  = true;
  bool _subiendoFoto = false;
  Uint8List? _fotoPreview;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nombreCtrl   = TextEditingController(text: user?.nombre   ?? '');
    _apellidoCtrl = TextEditingController(text: user?.apellido ?? '');
    _telefonoCtrl = TextEditingController(text: user?.telefono ?? '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _telefonoCtrl.dispose();
    _passActualCtrl.dispose();
    _passNuevaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFoto() async {
    final auth = context.read<AuthProvider>();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() { _fotoPreview = bytes; _subiendoFoto = true; });

    final ok = await auth.subirFotoPerfil(picked);

    if (mounted) {
      setState(() => _subiendoFoto = false);
      ScaffoldMessenger.of(context).showSnackBar(_snack(
        ok ? '✓ Foto actualizada' : 'Error al subir la foto', error: !ok,
      ));
    }
  }

  bool _passwordValida(String p) =>
      p.contains(RegExp(r'[A-Z]')) &&
      p.contains(RegExp(r'[a-z]')) &&
      p.contains(RegExp(r'[0-9]')) &&
      p.contains(RegExp(r'[^A-Za-z0-9]'));

  Future<void> _guardar() async {
    if (_cambiarPass &&
        (_passActualCtrl.text.isEmpty || _passNuevaCtrl.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(_snack(
        '⚠ Completá ambos campos de contraseña', error: true,
      ));
      return;
    }
    if (_cambiarPass && !_passwordValida(_passNuevaCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(_snack(
        'La contraseña debe tener al menos una mayúscula, una minúscula, un número y un símbolo.',
        error: true,
      ));
      return;
    }

    setState(() => _guardando = true);

    final ok = await context.read<AuthProvider>().actualizarPerfil(
      nombre:         _nombreCtrl.text.trim(),
      apellido:       _apellidoCtrl.text.trim(),
      telefono:       _telefonoCtrl.text.trim(),
      passwordActual: _cambiarPass ? _passActualCtrl.text : null,
      passwordNueva:  _cambiarPass ? _passNuevaCtrl.text  : null,
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (ok) {
      _passActualCtrl.clear();
      _passNuevaCtrl.clear();
      setState(() => _cambiarPass = false);
      ScaffoldMessenger.of(context).showSnackBar(
        _snack('✓ Perfil actualizado'),
      );
    } else {
      final err = context.read<AuthProvider>().error ?? 'Error al guardar';
      ScaffoldMessenger.of(context).showSnackBar(_snack(err, error: true));
    }
  }

  SnackBar _snack(String msg, {bool error = false}) => SnackBar(
    content: Text(msg,
      style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream),
    ),
    backgroundColor: error ? AppColors.charcoal : AppColors.ink,
    behavior: SnackBarBehavior.floating,
  );

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final user     = auth.user;
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: const AppNavBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 0,
          vertical: 48,
        ),
        child: Center(
          child: SizedBox(
            width: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Encabezado ────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: _subiendoFoto ? null : _pickFoto,
                      child: Stack(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.sand, width: 1),
                              color: AppColors.beige,
                            ),
                            child: ClipOval(
                              child: _subiendoFoto
                                  ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.charcoal))
                                  : _fotoPreview != null
                                      ? Image.memory(_fotoPreview!, fit: BoxFit.cover)
                                      : user?.fotoPerfilUrl != null
                                          ? Image.network(
                                              '${ApiService.serverUrl}${user!.fotoPerfilUrl}',
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => _avatarPlaceholder(user),
                                            )
                                          : _avatarPlaceholder(user),
                            ),
                          ),
                          Positioned(
                            bottom: 0, right: 0,
                            child: Container(
                              width: 24, height: 24,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.ink,
                              ),
                              child: const Icon(Icons.edit, size: 12, color: AppColors.cream),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mi perfil',
                          style: GoogleFonts.syne(
                            fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.ink,
                          ),
                        ),
                        Text('${user?.nombre ?? ''} ${user?.apellido ?? ''}',
                          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.charcoal),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // ── Datos no editables ────────────────────────
                Text('DATOS DE CUENTA',
                  style: GoogleFonts.dmMono(
                    fontSize: 10, color: AppColors.gray, letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoRow(label: 'Email', value: user?.email ?? ''),
                const SizedBox(height: 40),

                // ── Datos editables ───────────────────────────
                Text('DATOS PERSONALES',
                  style: GoogleFonts.dmMono(
                    fontSize: 10, color: AppColors.gray, letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 12),
                _campo('Nombre', _nombreCtrl),
                const SizedBox(height: 12),
                _campo('Apellido', _apellidoCtrl),
                const SizedBox(height: 12),
                _campo('Teléfono', _telefonoCtrl,
                  keyboardType: TextInputType.phone),
                const SizedBox(height: 40),

                // ── Contraseña ────────────────────────────────
                Text('CONTRASEÑA',
                  style: GoogleFonts.dmMono(
                    fontSize: 10, color: AppColors.gray, letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() => _cambiarPass = !_cambiarPass),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.sand),
                      color: AppColors.beige,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _cambiarPass
                              ? Icons.lock_open_outlined
                              : Icons.lock_outline,
                          size: 16, color: AppColors.stone,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _cambiarPass
                              ? 'Cancelar cambio de contraseña'
                              : 'Cambiar contraseña',
                          style: GoogleFonts.dmMono(
                            fontSize: 12, color: AppColors.charcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_cambiarPass) ...[
                  const SizedBox(height: 12),
                  _campoPwd('Contraseña actual', _passActualCtrl,
                    obscure: _obscuraActual,
                    onToggle: () =>
                        setState(() => _obscuraActual = !_obscuraActual),
                  ),
                  const SizedBox(height: 12),
                  _campoPwd('Contraseña nueva', _passNuevaCtrl,
                    obscure: _obscuraNueva,
                    onToggle: () =>
                        setState(() => _obscuraNueva = !_obscuraNueva),
                  ),
                ],
                const SizedBox(height: 48),

                // ── Mis órdenes ───────────────────────────────
                Text('MIS COMPRAS',
                  style: GoogleFonts.dmMono(
                    fontSize: 10, color: AppColors.gray, letterSpacing: 0.15,
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.go('/mis-ordenes'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.sand),
                      color: AppColors.beige,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 16, color: AppColors.stone),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Ver historial de órdenes',
                              style: GoogleFonts.dmMono(
                                  fontSize: 12, color: AppColors.charcoal)),
                        ),
                        const Icon(Icons.chevron_right,
                            size: 18, color: AppColors.stone),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // ── Guardar ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.cream,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: const RoundedRectangleBorder(),
                      elevation: 0,
                    ),
                    child: _guardando
                        ? const SizedBox(
                            height: 16, width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.cream,
                            ),
                          )
                        : Text('Guardar cambios',
                            style: GoogleFonts.dmMono(
                              fontSize: 12, letterSpacing: 0.1,
                            ),
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

  Widget _campo(String label, TextEditingController ctrl,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: _inputDeco(label),
      style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.ink),
    );
  }

  Widget _campoPwd(String label, TextEditingController ctrl,
      {required bool obscure, required VoidCallback onToggle}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: _inputDeco(label).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18, color: AppColors.stone,
          ),
          onPressed: onToggle,
          splashRadius: 18,
        ),
      ),
      style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.ink),
    );
  }

  Widget _avatarPlaceholder(user) {
    final initials = '${user?.nombre?.isNotEmpty == true ? user!.nombre[0] : ''}${user?.apellido?.isNotEmpty == true ? user!.apellido[0] : ''}'.toUpperCase();
    return Center(
      child: Text(initials.isEmpty ? '?' : initials,
        style: GoogleFonts.syne(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.stone),
      ),
    );
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
    border: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.sand),
    ),
    enabledBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.sand),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: AppColors.ink),
    ),
    filled: true,
    fillColor: AppColors.beige,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.sand),
        color: AppColors.beige,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
              style: GoogleFonts.dmMono(
                fontSize: 10, color: AppColors.stone, letterSpacing: 0.1,
              ),
            ),
          ),
          Text(value,
            style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.charcoal),
          ),
        ],
      ),
    );
  }
}
