import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/drops_provider.dart';
import '../providers/admin_provider.dart';
import '../providers/carrito_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AdminPreciosScreen extends StatefulWidget {
  const AdminPreciosScreen({super.key});

  @override
  State<AdminPreciosScreen> createState() => _AdminPreciosScreenState();
}

class _AdminPreciosScreenState extends State<AdminPreciosScreen> {
  final _porcentajeCtrl = TextEditingController();
  final Set<int> _seleccionados = {};
  bool _cargando = true;
  bool _aplicando = false;
  List<Producto> _productos = [];
  List<Drop> _drops = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _porcentajeCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    final adminProvider = context.read<AdminProvider>();
    final dropsProvider = context.read<DropsProvider>();
    await Future.wait([
      adminProvider.cargarMisProductos(),
      dropsProvider.cargarDrops(),
    ]);
    if (!mounted) return;
    setState(() {
      _productos = adminProvider.misProductos;
      _drops = dropsProvider.drops;
      _cargando = false;
    });
  }

  double? get _porcentaje {
    final txt = _porcentajeCtrl.text.trim().replaceAll('%', '');
    return double.tryParse(txt);
  }

  void _seleccionarTodos() {
    setState(() {
      if (_seleccionados.length == _productos.length) {
        _seleccionados.clear();
      } else {
        _seleccionados.addAll(_productos.map((p) => p.id));
      }
    });
  }

  void _seleccionarPorDrop(Drop drop) async {
    final idsDelDrop = await _getProductosDelDrop(drop.id);
    setState(() {
      _seleccionados.addAll(
        _productos.where((p) => idsDelDrop.contains(p.id)).map((p) => p.id),
      );
    });
  }

  Future<List<int>> _getProductosDelDrop(int dropId) async {
    try {
      final api = context.read<ApiService>();
      final lista = await api.getProductosDelDrop(dropId);
      return lista;
    } catch (_) {
      return [];
    }
  }

  String _precioPreview(Producto p) {
    final pct = _porcentaje;
    if (pct == null || !_seleccionados.contains(p.id)) return p.precioFormateado;
    final nuevo = p.precio * (1 + pct / 100);
    return '\$${nuevo.toStringAsFixed(0)}';
  }

  Color _precioColor(Producto p) {
    final pct = _porcentaje;
    if (pct == null || !_seleccionados.contains(p.id)) return AppColors.charcoal;
    return pct >= 0 ? Colors.green.shade700 : Colors.red.shade700;
  }

  Future<void> _aplicar() async {
    if (_seleccionados.isEmpty) return;
    final pct = _porcentaje;
    if (pct == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ingresá un porcentaje válido.',
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream)),
        backgroundColor: AppColors.charcoal, behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
      return;
    }

    final signo = pct >= 0 ? '+' : '';
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text('Confirmar ajuste',
          style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        content: Text(
          'Aplicás $signo${pct.toStringAsFixed(1)}% a ${_seleccionados.length} producto${_seleccionados.length > 1 ? 's' : ''}.\n\nEsta acción no se puede deshacer.',
          style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.charcoal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink, foregroundColor: AppColors.cream,
              elevation: 0, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text('Aplicar', style: GoogleFonts.dmMono(fontSize: 11)),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _aplicando = true);
    try {
      final res = await context.read<ApiService>().ajustarPrecios(
        productoIds: _seleccionados.toList(),
        porcentaje: pct,
      );
      if (!mounted) return;
      final actualizados = res['actualizados'] ?? _seleccionados.length;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ $actualizados producto${actualizados != 1 ? 's' : ''} actualizado${actualizados != 1 ? 's' : ''}.',
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream)),
        backgroundColor: AppColors.ink, behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
      _seleccionados.clear();
      _porcentajeCtrl.clear();
      // Refrescar carrito para reflejar precios actualizados
      context.read<CarritoProvider>().cargarCarrito();
      await _cargar();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message,
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream)),
        backgroundColor: AppColors.charcoal, behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    } finally {
      if (mounted) setState(() => _aplicando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: const AppNavBar(),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.charcoal))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 48, vertical: 40,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 720,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Ajuste de precios',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 36, fontWeight: FontWeight.w600, color: AppColors.ink,
                              ),
                            ),
                            Text('Seleccioná los productos y aplicá un porcentaje de ajuste.',
                              style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone)),
                            const SizedBox(height: 32),

                            // ── Barra de acciones ──────────────────────
                            _AccionesBar(
                              drops: _drops,
                              totalProductos: _productos.length,
                              seleccionados: _seleccionados.length,
                              onSeleccionarTodos: _seleccionarTodos,
                              onSeleccionarDrop: _seleccionarPorDrop,
                            ),
                            const SizedBox(height: 16),

                            // ── Lista productos ────────────────────────
                            if (_productos.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 48),
                                  child: Text('No hay productos publicados.',
                                    style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone)),
                                ),
                              )
                            else
                              ..._productos.map((p) => _ProductoCheckTile(
                                producto: p,
                                seleccionado: _seleccionados.contains(p.id),
                                precioPreview: _precioPreview(p),
                                precioColor: _precioColor(p),
                                onToggle: () => setState(() {
                                  if (_seleccionados.contains(p.id)) {
                                    _seleccionados.remove(p.id);
                                  } else {
                                    _seleccionados.add(p.id);
                                  }
                                }),
                              )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Panel inferior fijo ────────────────────────────
                _PanelAplicar(
                  ctrl: _porcentajeCtrl,
                  seleccionados: _seleccionados.length,
                  aplicando: _aplicando,
                  onAplicar: _aplicar,
                  onPorcentajeChanged: () => setState(() {}),
                ),
              ],
            ),
    );
  }
}

// ─── BARRA DE SELECCIÓN ────────────────────────────────────
class _AccionesBar extends StatelessWidget {
  final List<Drop> drops;
  final int totalProductos;
  final int seleccionados;
  final VoidCallback onSeleccionarTodos;
  final void Function(Drop) onSeleccionarDrop;

  const _AccionesBar({
    required this.drops,
    required this.totalProductos,
    required this.seleccionados,
    required this.onSeleccionarTodos,
    required this.onSeleccionarDrop,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Seleccionar todos
        OutlinedButton.icon(
          onPressed: onSeleccionarTodos,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.sand),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          icon: Icon(
            seleccionados == totalProductos
                ? Icons.check_box_outlined
                : Icons.check_box_outline_blank,
            size: 16, color: AppColors.charcoal,
          ),
          label: Text('Todos',
            style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.charcoal)),
        ),
        const SizedBox(width: 8),

        // Seleccionar por drop
        if (drops.isNotEmpty)
          PopupMenuButton<Drop>(
            onSelected: onSeleccionarDrop,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            color: AppColors.cream,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.sand),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_outlined, size: 16, color: AppColors.charcoal),
                  const SizedBox(width: 6),
                  Text('Por drop',
                    style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.charcoal)),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.stone),
                ],
              ),
            ),
            itemBuilder: (_) => drops.map((d) => PopupMenuItem(
              value: d,
              child: Text(d.nombre,
                style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.ink)),
            )).toList(),
          ),

        const Spacer(),
        if (seleccionados > 0)
          Text('$seleccionados seleccionado${seleccionados > 1 ? 's' : ''}',
            style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone)),
      ],
    );
  }
}

// ─── TILE DE PRODUCTO ──────────────────────────────────────
class _ProductoCheckTile extends StatelessWidget {
  final Producto producto;
  final bool seleccionado;
  final String precioPreview;
  final Color precioColor;
  final VoidCallback onToggle;

  const _ProductoCheckTile({
    required this.producto,
    required this.seleccionado,
    required this.precioPreview,
    required this.precioColor,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.beige : AppColors.cream,
          border: Border.all(
            color: seleccionado ? AppColors.charcoal : AppColors.sand,
            width: seleccionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              seleccionado ? Icons.check_box_outlined : Icons.check_box_outline_blank,
              size: 18, color: seleccionado ? AppColors.ink : AppColors.stone,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(producto.titulo,
                    style: GoogleFonts.syne(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                  ),
                  Text(producto.categoria.toUpperCase(),
                    style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.stone, letterSpacing: 0.1)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(precioPreview,
                  style: GoogleFonts.dmMono(
                    fontSize: 13, fontWeight: FontWeight.w700, color: precioColor)),
                if (seleccionado && precioPreview != producto.precioFormateado)
                  Text(producto.precioFormateado,
                    style: GoogleFonts.dmMono(
                      fontSize: 10, color: AppColors.stone,
                      decoration: TextDecoration.lineThrough,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PANEL INFERIOR ────────────────────────────────────────
class _PanelAplicar extends StatelessWidget {
  final TextEditingController ctrl;
  final int seleccionados;
  final bool aplicando;
  final VoidCallback onAplicar;
  final VoidCallback onPorcentajeChanged;

  const _PanelAplicar({
    required this.ctrl,
    required this.seleccionados,
    required this.aplicando,
    required this.onAplicar,
    required this.onPorcentajeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(top: BorderSide(color: AppColors.sand)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Input porcentaje
            SizedBox(
              width: 160,
              child: TextField(
                controller: ctrl,
                onChanged: (_) => onPorcentajeChanged(),
                keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                style: GoogleFonts.dmMono(fontSize: 14, color: AppColors.ink),
                decoration: InputDecoration(
                  hintText: 'Ej: +15 o -10',
                  hintStyle: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
                  suffixText: '%',
                  suffixStyle: GoogleFonts.dmMono(fontSize: 13, color: AppColors.charcoal),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                    borderSide: BorderSide(color: AppColors.charcoal),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: seleccionados == 0
                    ? 'Seleccioná productos'
                    : 'Aplicar a $seleccionados producto${seleccionados > 1 ? 's' : ''}',
                fullWidth: true,
                loading: aplicando,
                onPressed: seleccionados > 0 ? onAplicar : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
