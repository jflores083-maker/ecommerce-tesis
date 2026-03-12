import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../app_constants.dart';
import '../providers/admin_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _tituloCtrl      = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _precioCtrl      = TextEditingController();
  final _stockCtrl       = TextEditingController();
  final _colorCtrl       = TextEditingController();

  String _categoriaSeleccionada = 'Remeras';
  String _estadoSeleccionado    = 'disponible';
  final Set<String> _tallesSeleccionados = {};
  XFile? _imagenSeleccionada;
  Uint8List? _imagenBytes;

  static List<String> get _categorias => AppCategorias.todas;
  static const _estados    = ['disponible', 'no disponible'];
  static const _talles     = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imagenSeleccionada = picked;
        _imagenBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    final titulo      = _tituloCtrl.text.trim();
    final descripcion = _descripcionCtrl.text.trim();
    final precioStr   = _precioCtrl.text.trim();
    final stockStr    = _stockCtrl.text.trim();

    if (titulo.isEmpty || descripcion.isEmpty || precioStr.isEmpty || stockStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Completá todos los campos obligatorios',
              style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream)),
          backgroundColor: AppColors.charcoal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final precio = double.tryParse(precioStr.replaceAll(',', '.'));
    final stock  = int.tryParse(stockStr);

    if (precio == null || precio <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Precio inválido',
              style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream)),
          backgroundColor: AppColors.charcoal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (stock == null || stock < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock inválido',
              style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream)),
          backgroundColor: AppColors.charcoal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_tallesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seleccioná al menos un talle',
              style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream)),
          backgroundColor: AppColors.charcoal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final admin = context.read<AdminProvider>();
    final ok = await admin.crearProducto(
      titulo:      titulo,
      descripcion: descripcion,
      precio:      precio,
      stock:       stock,
      talles:      _tallesSeleccionados.toList(),
      categoria:   _categoriaSeleccionada,
      estado:      _estadoSeleccionado,
      color:       _colorCtrl.text.trim().isEmpty ? null : _colorCtrl.text.trim(),
      imagen:      _imagenSeleccionada,
    );

    if (ok && mounted) {
      _tituloCtrl.clear();
      _descripcionCtrl.clear();
      _precioCtrl.clear();
      _stockCtrl.clear();
      _colorCtrl.clear();
      setState(() {
        _tallesSeleccionados.clear();
        _imagenSeleccionada = null;
        _imagenBytes = null;
        _categoriaSeleccionada = 'Remeras';
        _estadoSeleccionado = 'disponible';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Producto creado correctamente',
              style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream)),
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin    = context.watch<AdminProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppColors.cream,
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
                Text('Admin — nuevo producto',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 40, fontWeight: FontWeight.w300, color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Panel de gestión de productos 638.',
                  style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
                ),
                const SizedBox(height: 40),

                // ── Error ────────────────────────────
                if (admin.error != null) ...[
                  ErrorMsg(admin.error!),
                  const SizedBox(height: 16),
                ],

                // ── Título ───────────────────────────
                AuthField(label: 'TÍTULO *', controller: _tituloCtrl),
                const SizedBox(height: 16),

                // ── Descripción ──────────────────────
                _TextAreaField(label: 'DESCRIPCIÓN *', controller: _descripcionCtrl),
                const SizedBox(height: 16),

                // ── Precio + Stock ───────────────────
                Row(
                  children: [
                    Expanded(
                      child: AuthField(
                        label: 'PRECIO *',
                        controller: _precioCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        hint: '0.00',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AuthField(
                        label: 'STOCK *',
                        controller: _stockCtrl,
                        keyboardType: TextInputType.number,
                        hint: '0',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Color (opcional) ─────────────────
                AuthField(label: 'COLOR (OPCIONAL)', controller: _colorCtrl, hint: 'Negro, Blanco…'),
                const SizedBox(height: 24),

                // ── Categoría ────────────────────────
                _LabeledSection(
                  label: 'CATEGORÍA',
                  child: _DropdownField(
                    value: _categoriaSeleccionada,
                    items: _categorias,
                    onChanged: (v) => setState(() => _categoriaSeleccionada = v!),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Estado ───────────────────────────
                _LabeledSection(
                  label: 'ESTADO',
                  child: Row(
                    children: _estados.map((e) {
                      final selected = e == _estadoSeleccionado;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => setState(() => _estadoSeleccionado = e),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? AppColors.ink : Colors.transparent,
                              border: Border.all(
                                color: selected ? AppColors.ink : AppColors.sand,
                              ),
                            ),
                            child: Text(e,
                              style: GoogleFonts.dmMono(
                                fontSize: 11,
                                color: selected ? AppColors.cream : AppColors.gray,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Talles multiselect ───────────────
                _LabeledSection(
                  label: 'TALLES *',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _talles.map((t) {
                      final selected = _tallesSeleccionados.contains(t);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (selected) {
                            _tallesSeleccionados.remove(t);
                          } else {
                            _tallesSeleccionados.add(t);
                          }
                        }),
                        child: Container(
                          width: 52,
                          height: 36,
                          decoration: BoxDecoration(
                            color: selected ? AppColors.ink : Colors.transparent,
                            border: Border.all(
                              color: selected ? AppColors.ink : AppColors.sand,
                            ),
                          ),
                          child: Center(
                            child: Text(t,
                              style: GoogleFonts.dmMono(
                                fontSize: 11,
                                color: selected ? AppColors.cream : AppColors.gray,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Foto principal ───────────────────
                _LabeledSection(
                  label: 'FOTO PRINCIPAL',
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.beige,
                        border: Border.all(color: AppColors.sand),
                      ),
                      child: _imagenSeleccionada != null
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.memory(_imagenBytes!, fit: BoxFit.cover),
                                Positioned(
                                  top: 8, right: 8,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _imagenSeleccionada = null),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      color: AppColors.ink,
                                      child: const Icon(Icons.close, size: 14, color: AppColors.cream),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_photo_alternate_outlined,
                                    size: 32, color: AppColors.stone),
                                const SizedBox(height: 8),
                                Text('Seleccionar imagen',
                                  style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // ── Botón submit ─────────────────────
                PrimaryButton(
                  label: 'Publicar producto',
                  fullWidth: true,
                  loading: admin.loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────

class _LabeledSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.gray, letterSpacing: 0.15),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _TextAreaField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _TextAreaField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
          style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.gray, letterSpacing: 0.15),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.charcoal),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.sand),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.sand),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.charcoal),
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _DropdownField({required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.sand),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.charcoal),
          icon: const Icon(Icons.expand_more, size: 18, color: AppColors.stone),
          onChanged: onChanged,
          items: items
              .map((i) => DropdownMenuItem(
                    value: i,
                    child: Text(i, style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.charcoal)),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
