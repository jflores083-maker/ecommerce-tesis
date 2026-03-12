import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../app_constants.dart';
import '../providers/admin_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AdminModificarScreen extends StatefulWidget {
  const AdminModificarScreen({super.key});

  @override
  State<AdminModificarScreen> createState() => _AdminModificarScreenState();
}

class _AdminModificarScreenState extends State<AdminModificarScreen> {
  Producto? _seleccionado;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().cargarMisProductos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin    = context.watch<AdminProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: const AppNavBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 0, vertical: 48),
        child: Center(
          child: SizedBox(
            width: 560,
            child: _seleccionado == null
                ? _ListaProductos(
                    admin: admin,
                    onSeleccionar: (p) => setState(() => _seleccionado = p),
                  )
                : _FormEditar(
                    producto: _seleccionado!,
                    onVolver: () => setState(() => _seleccionado = null),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Lista de productos para seleccionar ────────────────────

class _ListaProductos extends StatelessWidget {
  final AdminProvider admin;
  final ValueChanged<Producto> onSeleccionar;
  const _ListaProductos({required this.admin, required this.onSeleccionar});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Modificar producto',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 40, fontWeight: FontWeight.w300, color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text('Seleccioná el producto que querés editar.',
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
        ),
        const SizedBox(height: 40),
        if (admin.loading)
          const Center(child: CircularProgressIndicator(color: AppColors.charcoal))
        else if (admin.error != null)
          ErrorMsg(admin.error!)
        else if (admin.misProductos.isEmpty)
          Text('No tenés productos publicados.',
            style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone),
          )
        else
          ...admin.misProductos.map((p) => _ProductoRow(
            producto: p,
            onTap: () => onSeleccionar(p),
          )),
      ],
    );
  }
}

class _ProductoRow extends StatelessWidget {
  final Producto producto;
  final VoidCallback onTap;
  const _ProductoRow({required this.producto, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final url = producto.imagenPrincipalUrl;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 64, height: 80,
                  child: url != null && url.isNotEmpty
                      ? Image.network('${ApiService.serverUrl}$url', fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: AppColors.beige))
                      : Container(color: AppColors.beige,
                          child: Center(child: Icon(Icons.shopping_bag_outlined,
                              size: 24, color: AppColors.stone.withOpacity(0.3)))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(producto.titulo,
                        style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 4),
                      Text(producto.precioFormateado,
                        style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.gray),
                      ),
                      Text('Stock: ${producto.stock}  ·  ${producto.categoria}',
                        style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.stone),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined, size: 18, color: AppColors.stone),
              ],
            ),
          ),
        ),
        const Divider(color: AppColors.sand, height: 1, thickness: 1),
      ],
    );
  }
}

// ── Formulario de edición ──────────────────────────────────

class _FormEditar extends StatefulWidget {
  final Producto producto;
  final VoidCallback onVolver;
  const _FormEditar({required this.producto, required this.onVolver});

  @override
  State<_FormEditar> createState() => _FormEditarState();
}

class _FormEditarState extends State<_FormEditar> {
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _colorCtrl;
  late String _categoriaSeleccionada;
  late String _estadoSeleccionado;
  late Set<String> _tallesSeleccionados;

  static const _estados = ['disponible', 'no disponible'];
  static const _talles  = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    _tituloCtrl      = TextEditingController(text: p.titulo);
    _descripcionCtrl = TextEditingController(text: p.descripcion);
    _precioCtrl      = TextEditingController(text: p.precio.toStringAsFixed(2));
    _stockCtrl       = TextEditingController(text: p.stock.toString());
    _colorCtrl       = TextEditingController(text: p.color ?? '');
    _categoriaSeleccionada = AppCategorias.todas.contains(p.categoria) ? p.categoria : AppCategorias.todas.first;
    _estadoSeleccionado    = p.estado;
    _tallesSeleccionados   = Set<String>.from(p.talles);
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final titulo      = _tituloCtrl.text.trim();
    final descripcion = _descripcionCtrl.text.trim();
    final precioStr   = _precioCtrl.text.trim();
    final stockStr    = _stockCtrl.text.trim();

    if (titulo.isEmpty || descripcion.isEmpty || precioStr.isEmpty || stockStr.isEmpty) {
      _snack('Completá todos los campos obligatorios', error: true); return;
    }

    final precio = double.tryParse(precioStr.replaceAll(',', '.'));
    if (precio == null || precio <= 0) { _snack('Precio inválido', error: true); return; }

    final stock = int.tryParse(stockStr);
    if (stock == null || stock < 0) { _snack('Stock inválido', error: true); return; }

    if (_tallesSeleccionados.isEmpty) { _snack('Seleccioná al menos un talle', error: true); return; }

    final tallesJson = '[${_tallesSeleccionados.map((t) => '"$t"').join(',')}]';

    final campos = <String, dynamic>{
      'titulo':      titulo,
      'descripcion': descripcion,
      'precio':      precio,
      'stock':       stock,
      'talles':      tallesJson,
      'categoria':   _categoriaSeleccionada,
      'estado':      _estadoSeleccionado,
      if (_colorCtrl.text.trim().isNotEmpty) 'color': _colorCtrl.text.trim(),
    };

    final admin = context.read<AdminProvider>();
    final ok = await admin.modificarProducto(widget.producto.id, campos);

    if (mounted) {
      if (ok) {
        _snack('Producto actualizado correctamente');
        widget.onVolver();
      }
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream)),
      backgroundColor: error ? AppColors.charcoal : AppColors.ink,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: widget.onVolver,
              child: const Icon(Icons.arrow_back, size: 18, color: AppColors.charcoal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Editando: ${widget.producto.titulo}',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 28, fontWeight: FontWeight.w300, color: AppColors.ink,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        if (admin.error != null) ...[
          ErrorMsg(admin.error!),
          const SizedBox(height: 16),
        ],

        AuthField(label: 'TÍTULO *', controller: _tituloCtrl),
        const SizedBox(height: 16),
        _TextAreaField(label: 'DESCRIPCIÓN *', controller: _descripcionCtrl),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: AuthField(
                label: 'PRECIO *',
                controller: _precioCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AuthField(
                label: 'STOCK *',
                controller: _stockCtrl,
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AuthField(label: 'COLOR (OPCIONAL)', controller: _colorCtrl),
        const SizedBox(height: 24),

        _LabeledSection(
          label: 'CATEGORÍA',
          child: _DropdownField(
            value: _categoriaSeleccionada,
            items: AppCategorias.todas,
            onChanged: (v) => setState(() => _categoriaSeleccionada = v!),
          ),
        ),
        const SizedBox(height: 24),

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
                      border: Border.all(color: selected ? AppColors.ink : AppColors.sand),
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

        _LabeledSection(
          label: 'TALLES *',
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: _talles.map((t) {
              final selected = _tallesSeleccionados.contains(t);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) _tallesSeleccionados.remove(t);
                  else _tallesSeleccionados.add(t);
                }),
                child: Container(
                  width: 52, height: 36,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.ink : Colors.transparent,
                    border: Border.all(color: selected ? AppColors.ink : AppColors.sand),
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
        const SizedBox(height: 40),

        PrimaryButton(
          label: 'Guardar cambios',
          fullWidth: true,
          loading: admin.loading,
          onPressed: _guardar,
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}

// ── Helpers ────────────────────────────────────────────────

class _LabeledSection extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledSection({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.gray, letterSpacing: 0.15)),
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
        Text(label, style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.gray, letterSpacing: 0.15)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.charcoal),
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sand)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.sand)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.charcoal)),
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
      decoration: BoxDecoration(border: Border.all(color: AppColors.sand)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.charcoal),
          icon: const Icon(Icons.expand_more, size: 18, color: AppColors.stone),
          onChanged: onChanged,
          items: items.map((i) => DropdownMenuItem(
            value: i,
            child: Text(i, style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.charcoal)),
          )).toList(),
        ),
      ),
    );
  }
}
