import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AdminCategoriasScreen extends StatefulWidget {
  const AdminCategoriasScreen({super.key});

  @override
  State<AdminCategoriasScreen> createState() => _AdminCategoriasScreenState();
}

class _AdminCategoriasScreenState extends State<AdminCategoriasScreen> {
  late List<String> _categorias;
  final _nuevaCtrl = TextEditingController();
  bool _guardando = false;
  bool _inicializado = false;

  @override
  void dispose() {
    _nuevaCtrl.dispose();
    super.dispose();
  }

  void _inicializar(ConfigProvider config) {
    if (_inicializado) return;
    _categorias = List.of(config.categorias);
    _inicializado = true;
  }

  void _agregar() {
    final nueva = _nuevaCtrl.text.trim();
    if (nueva.isEmpty) return;
    if (_categorias.any((c) => c.toLowerCase() == nueva.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ya existe esa categoría.',
            style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream)),
        backgroundColor: AppColors.charcoal,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() {
      _categorias.add(nueva);
      _nuevaCtrl.clear();
    });
  }

  void _eliminar(int index) {
    setState(() => _categorias.removeAt(index));
  }

  Future<void> _guardar() async {
    if (_categorias.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Debe haber al menos una categoría.',
            style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream)),
        backgroundColor: AppColors.charcoal,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _guardando = true);
    final ok = await context.read<ConfigProvider>().guardarCategorias(_categorias);
    if (mounted) {
      setState(() => _guardando = false);
      if (ok) {
        context.go('/admin');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar.',
              style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream)),
          backgroundColor: AppColors.charcoal,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    _inicializar(config);
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
                Text('Categorías',
                    style: GoogleFonts.syne(
                        fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(height: 4),
                Text('Agregá o eliminá categorías de productos.',
                    style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone)),
                const SizedBox(height: 40),

                // ── Lista actual ──────────────────────────────
                Text('CATEGORÍAS ACTUALES',
                    style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.gray, letterSpacing: 0.15)),
                const SizedBox(height: 12),
                if (_categorias.isEmpty)
                  Text('Sin categorías.',
                      style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone))
                else
                  ...List.generate(_categorias.length, (i) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.sand),
                      color: AppColors.beige,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_categorias[i],
                            style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.ink)),
                        GestureDetector(
                          onTap: () => _eliminar(i),
                          child: const Icon(Icons.close, size: 16, color: AppColors.stone),
                        ),
                      ],
                    ),
                  )),

                const SizedBox(height: 32),

                // ── Agregar nueva ─────────────────────────────
                Text('AGREGAR CATEGORÍA',
                    style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.gray, letterSpacing: 0.15)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nuevaCtrl,
                        textCapitalization: TextCapitalization.words,
                        onSubmitted: (_) => _agregar(),
                        decoration: InputDecoration(
                          hintText: 'Ej: Vestidos',
                          hintStyle: GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone),
                          border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sand)),
                          enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sand)),
                          focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.ink)),
                          filled: true,
                          fillColor: AppColors.beige,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.ink),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _agregar,
                      child: Container(
                        height: 50,
                        width: 50,
                        color: AppColors.ink,
                        child: const Icon(Icons.add, color: AppColors.cream, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

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
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cream))
                        : Text('Guardar y volver',
                            style: GoogleFonts.dmMono(fontSize: 12, letterSpacing: 0.1)),
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
