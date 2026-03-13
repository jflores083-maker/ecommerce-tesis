import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/drops_provider.dart';
import '../providers/productos_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AdminCrearDropScreen extends StatefulWidget {
  const AdminCrearDropScreen({super.key});

  @override
  State<AdminCrearDropScreen> createState() => _AdminCrearDropScreenState();
}

class _AdminCrearDropScreenState extends State<AdminCrearDropScreen> {
  final _nombreCtrl = TextEditingController();
  XFile? _imagen;
  Uint8List? _previewBytes;
  final Set<int> _seleccionados = {};
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductosProvider>().cargarProductos();
    });
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImagen() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() { _imagen = picked; _previewBytes = bytes; });
  }

  Future<void> _guardar() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('El nombre es requerido.',
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream),
        ),
        backgroundColor: AppColors.charcoal,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _guardando = true);
    final ok = await context.read<DropsProvider>().crearDrop(
      nombre: _nombreCtrl.text.trim(),
      productoIds: _seleccionados.toList(),
      imagen: _imagen,
    );

    if (mounted) {
      setState(() => _guardando = false);
      if (ok) {
        context.go('/admin/drops');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al crear el drop.',
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
    final isMobile = MediaQuery.of(context).size.width < 768;
    final productos = context.watch<ProductosProvider>().productos;

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
                Text('Nuevo drop',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 40, fontWeight: FontWeight.w300, color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Creá un nuevo lanzamiento y asociá productos.',
                  style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
                ),
                const SizedBox(height: 40),

                // ── Nombre ──
                Text('NOMBRE DEL DROP',
                  style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.gray, letterSpacing: 0.15),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nombreCtrl,
                  decoration: InputDecoration(
                    hintText: 'Ej: Colección Invierno 2025',
                    hintStyle: GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone),
                    border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sand)),
                    enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sand)),
                    focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.ink)),
                    filled: true,
                    fillColor: AppColors.beige,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: GoogleFonts.syne(fontSize: 18, color: AppColors.ink),
                ),
                const SizedBox(height: 40),

                // ── Imagen ──
                Text('IMAGEN DE PORTADA',
                  style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.gray, letterSpacing: 0.15),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImagen,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.sand),
                      color: AppColors.beige,
                    ),
                    child: _previewBytes != null
                        ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.stone),
                              const SizedBox(height: 8),
                              Text('Seleccionar imagen',
                                style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 40),

                // ── Productos ──
                Text('PRODUCTOS DEL DROP',
                  style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.gray, letterSpacing: 0.15),
                ),
                const SizedBox(height: 4),
                Text('Seleccioná los productos que forman parte de este lanzamiento.',
                  style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.stone),
                ),
                const SizedBox(height: 12),
                productos.isEmpty
                    ? Text('Cargando productos...',
                        style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone),
                      )
                    : Column(
                        children: productos.map((p) {
                          final sel = _seleccionados.contains(p.id);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (sel) _seleccionados.remove(p.id);
                              else _seleccionados.add(p.id);
                            }),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: sel ? AppColors.ink : AppColors.sand,
                                  width: sel ? 2 : 1,
                                ),
                                color: sel ? AppColors.ink.withValues(alpha: 0.04) : AppColors.cream,
                              ),
                              child: Row(
                                children: [
                                  // Miniatura
                                  SizedBox(
                                    width: 48, height: 48,
                                    child: p.imagenPrincipalUrl != null
                                        ? Image.network(
                                            '${ApiService.serverUrl}${p.imagenPrincipalUrl}',
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(color: AppColors.sand),
                                          )
                                        : Container(color: AppColors.sand),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.titulo,
                                          style: GoogleFonts.syne(
                                            fontSize: 13, fontWeight: FontWeight.w600,
                                            color: AppColors.ink,
                                          ),
                                        ),
                                        Text(p.precioFormateado,
                                          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (sel)
                                    const Icon(Icons.check_circle, size: 20, color: AppColors.ink),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 40),

                // ── Guardar ──
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
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream))
                        : Text('Publicar drop',
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
}
