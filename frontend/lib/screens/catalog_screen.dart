import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/config_provider.dart';
import '../models/models.dart';
import '../providers/productos_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class CatalogScreen extends StatefulWidget {
  final String? categoriaInicial;
  const CatalogScreen({super.key, this.categoriaInicial});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  List<String> get _categorias => ['Todos', ...context.read<ConfigProvider>().categorias];
  final _searchCtrl = TextEditingController();

  String _search = '';
  String? _talleSeleccionado;
  String? _colorSeleccionado;
  RangeValues? _precioRango;

  final _talles = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductosProvider>().cargarProductos(
            categoria: widget.categoriaInicial,
          );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Producto> _filtrar(List<Producto> todos) {
    return todos.where((p) {
      // Búsqueda por texto
      if (_search.isNotEmpty) {
        final q = _search.toLowerCase();
        if (!p.titulo.toLowerCase().contains(q) &&
            !(p.descripcion ?? '').toLowerCase().contains(q)) {
          return false;
        }
      }
      // Filtro talle
      if (_talleSeleccionado != null) {
        if (!p.talles.any((t) => t.toUpperCase() == _talleSeleccionado!)) {
          return false;
        }
      }
      // Filtro rango de precio
      if (_precioRango != null) {
        if (p.precio < _precioRango!.start || p.precio > _precioRango!.end) return false;
      }
      // Filtro color
      if (_colorSeleccionado != null && _colorSeleccionado!.isNotEmpty) {
        final color = (p.color ?? '').toLowerCase();
        if (!color.contains(_colorSeleccionado!.toLowerCase())) return false;
      }
      return true;
    }).toList();
  }

  void _limpiarFiltros() {
    setState(() {
      _search = '';
      _searchCtrl.clear();
      _talleSeleccionado = null;
      _precioRango = null;
      _colorSeleccionado = null;
    });
  }

  bool get _hayFiltrosActivos =>
      _search.isNotEmpty ||
      _talleSeleccionado != null ||
      _precioRango != null ||
      _colorSeleccionado != null;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductosProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;
    final px = isMobile ? 20.0 : 64.0;
    final filtrados = _filtrar(provider.productos);

    return Scaffold(
      appBar: const AppNavBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(px, 40, px, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Colección',
                  style: GoogleFonts.syne(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  '${filtrados.length} productos',
                  style:
                      GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
                ),
              ],
            ),
          ),

          // Barra de búsqueda
          Padding(
            padding: EdgeInsets.fromLTRB(px, 20, px, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                hintStyle:
                    GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone),
                prefixIcon:
                    const Icon(Icons.search, size: 18, color: AppColors.stone),
                suffixIcon: _search.isNotEmpty
                    ? GestureDetector(
                        onTap: () => setState(() {
                          _search = '';
                          _searchCtrl.clear();
                        }),
                        child: const Icon(Icons.close,
                            size: 16, color: AppColors.stone),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.beige,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
                  borderSide: BorderSide(color: AppColors.ink, width: 1.5),
                ),
              ),
            ),
          ),

          // Filtros
          Container(
            margin: EdgeInsets.fromLTRB(px, 12, px, 0),
            padding: const EdgeInsets.only(bottom: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.sand)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categorías
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categorias
                        .map((cat) => _FilterChip(
                              label: cat,
                              active: (provider.categoriaActiva.isEmpty &&
                                      cat == 'Todos') ||
                                  provider.categoriaActiva == cat,
                              onTap: () => provider.cargarProductos(
                                categoria: cat == 'Todos' ? null : cat,
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 10),
                // Talles + precio + color + limpiar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Talles
                      ..._talles.map((t) => _FilterChip(
                            label: t,
                            active: _talleSeleccionado == t,
                            onTap: () => setState(
                              () => _talleSeleccionado =
                                  _talleSeleccionado == t ? null : t,
                            ),
                          )),
                      const SizedBox(width: 8),
                      // Rango de precio
                      _PrecioRangoBtn(
                        valor: _precioRango,
                        maxPrecio: provider.productos.isEmpty
                            ? 100000
                            : provider.productos
                                .map((p) => p.precio)
                                .reduce((a, b) => a > b ? a : b),
                        onChanged: (v) => setState(() => _precioRango = v),
                      ),
                      const SizedBox(width: 8),
                      // Color
                      _ColorDropdown(
                        valor: _colorSeleccionado,
                        colores: provider.productos
                            .map((p) => p.color?.trim())
                            .where((c) => c != null && c.isNotEmpty)
                            .cast<String>()
                            .toSet()
                            .toList()
                          ..sort(),
                        onChanged: (v) =>
                            setState(() => _colorSeleccionado = v),
                      ),
                      // Limpiar filtros
                      if (_hayFiltrosActivos) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _limpiarFiltros,
                          child: Row(
                            children: [
                              const Icon(Icons.close,
                                  size: 12, color: AppColors.stone),
                              const SizedBox(width: 4),
                              Text(
                                'Limpiar filtros',
                                style: GoogleFonts.dmMono(
                                  fontSize: 10,
                                  color: AppColors.stone,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Grid
          Expanded(
            child: provider.loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.charcoal))
                : provider.error != null
                    ? Center(child: ErrorMsg(provider.error!))
                    : filtrados.isEmpty
                        ? Center(
                            child: Text(
                              'No hay productos que coincidan.',
                              style: GoogleFonts.dmMono(
                                  fontSize: 12, color: AppColors.stone),
                            ),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.fromLTRB(px, 32, px, 80),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isMobile ? 2 : 4,
                              crossAxisSpacing: isMobile ? 12 : 24,
                              mainAxisSpacing: isMobile ? 20 : 32,
                              childAspectRatio: isMobile ? 0.50 : 0.55,
                            ),
                            itemCount: filtrados.length,
                            itemBuilder: (_, i) =>
                                ProductCard(producto: filtrados[i]),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Chips de filtro ──────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          border:
              Border.all(color: active ? AppColors.charcoal : AppColors.sand),
          color: active ? AppColors.beige : Colors.transparent,
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.dmMono(
            fontSize: 10,
            color: active ? AppColors.ink : AppColors.gray,
            letterSpacing: 0.12,
          ),
        ),
      ),
    );
  }
}

// ── Dropdown precio máximo ───────────────────────────────────
class _PrecioRangoBtn extends StatelessWidget {
  final RangeValues? valor;
  final double maxPrecio;
  final ValueChanged<RangeValues?> onChanged;
  const _PrecioRangoBtn({required this.valor, required this.maxPrecio, required this.onChanged});

  String get _label {
    if (valor == null) return 'PRECIO';
    final min = valor!.start > 0 ? '\$${valor!.start.toStringAsFixed(0)}' : '\$0';
    final max = valor!.end == double.infinity ? 'sin límite' : '\$${valor!.end.toStringAsFixed(0)}';
    return '$min – $max';
  }

  @override
  Widget build(BuildContext context) {
    final activo = valor != null;
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<RangeValues?>(
          context: context,
          builder: (_) => _PrecioRangoDialog(
            inicial: valor ?? const RangeValues(0, double.infinity),
          ),
        );
        if (result == null) {
          onChanged(null);
        } else {
          final sinFiltro = result.start == 0 && result.end == double.infinity;
          onChanged(sinFiltro ? null : result);
        }
      },
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: activo ? AppColors.charcoal : AppColors.sand),
          color: activo ? AppColors.beige : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _label,
              style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.ink, letterSpacing: 0.12),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.stone),
          ],
        ),
      ),
    );
  }
}

class _PrecioRangoDialog extends StatefulWidget {
  final RangeValues inicial;
  const _PrecioRangoDialog({required this.inicial});

  @override
  State<_PrecioRangoDialog> createState() => _PrecioRangoDialogState();
}

class _PrecioRangoDialogState extends State<_PrecioRangoDialog> {
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _minCtrl = TextEditingController(
      text: widget.inicial.start > 0 ? widget.inicial.start.toStringAsFixed(0) : '',
    );
    _maxCtrl = TextEditingController(
      text: widget.inicial.end < double.infinity ? widget.inicial.end.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _aplicar() {
    final min = double.tryParse(_minCtrl.text.trim()) ?? 0;
    final max = double.tryParse(_maxCtrl.text.trim());
    if (max != null && max < min) {
      setState(() => _error = 'El máximo debe ser mayor al mínimo.');
      return;
    }
    Navigator.pop(context, RangeValues(min, max ?? double.infinity));
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
        prefixText: '\$ ',
        prefixStyle: GoogleFonts.dmMono(fontSize: 13, color: AppColors.ink),
        border: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sand)),
        enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sand)),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.ink)),
        filled: true,
        fillColor: AppColors.beige,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(),
      elevation: 0,
      title: Text('Rango de precio',
          style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco('Mínimo'),
                    style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.ink),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('–', style: GoogleFonts.dmMono(fontSize: 14, color: AppColors.stone)),
                ),
                Expanded(
                  child: TextField(
                    controller: _maxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDeco('Máximo'),
                    style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.ink),
                    onChanged: (_) => setState(() => _error = null),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: GoogleFonts.dmMono(fontSize: 10, color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text('Limpiar', style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone)),
        ),
        TextButton(
          onPressed: _aplicar,
          child: Text('Aplicar', style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.ink)),
        ),
      ],
    );
  }
}

// ── Dropdown color ───────────────────────────────────────────
class _ColorDropdown extends StatelessWidget {
  final String? valor;
  final List<String> colores;
  final ValueChanged<String?> onChanged;
  const _ColorDropdown({required this.valor, required this.colores, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final items = [null, ...colores];
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(
            color: valor != null ? AppColors.charcoal : AppColors.sand),
        color: valor != null ? AppColors.beige : Colors.transparent,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: valor,
          isDense: true,
          focusColor: Colors.transparent,
          style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.ink),
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 14, color: AppColors.stone),
          items: items
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      (c ?? 'Color').toUpperCase(),
                      style: GoogleFonts.dmMono(
                          fontSize: 10,
                          color: AppColors.ink,
                          letterSpacing: 0.12),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
