import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AdminCodigosScreen extends StatefulWidget {
  const AdminCodigosScreen({super.key});

  @override
  State<AdminCodigosScreen> createState() => _AdminCodigosScreenState();
}

class _AdminCodigosScreenState extends State<AdminCodigosScreen> {
  List<dynamic> _codigos = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      final api = context.read<ApiService>();
      final lista = await api.getCodigosPromocion();
      setState(() { _codigos = lista; _cargando = false; });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _cargando = false; });
    }
  }

  Future<void> _eliminar(int id, String codigo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: Text('Eliminar código',
          style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        content: Text('¿Eliminás el código "$codigo"?',
          style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.charcoal)),
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
            child: Text('Eliminar', style: GoogleFonts.dmMono(fontSize: 11)),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ApiService>().eliminarCodigoPromocion(id);
      if (mounted) _cargar();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.message, style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream)),
        backgroundColor: AppColors.charcoal, behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _abrirCrear() {
    showDialog(
      context: context,
      builder: (_) => _CrearCodigoDialog(onCreado: _cargar),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppNavBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Center(
          child: SizedBox(
            width: 620,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Códigos de promoción',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 36, fontWeight: FontWeight.w600, color: AppColors.ink,
                          ),
                        ),
                        Text('Creá y gestioná descuentos para tus clientes.',
                          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
                        ),
                      ],
                    ),
                    PrimaryButton(label: '+ Nuevo código', onPressed: _abrirCrear),
                  ],
                ),
                const SizedBox(height: 40),

                if (_cargando)
                  const Center(child: CircularProgressIndicator(color: AppColors.charcoal))
                else if (_error != null)
                  ErrorMsg(_error!)
                else if (_codigos.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Text('No hay códigos creados todavía.',
                        style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone)),
                    ),
                  )
                else
                  ..._codigos.map((c) => _CodigoTile(
                    codigo: c,
                    onEliminar: () => _eliminar(c['id'], c['codigo']),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── TILE ──────────────────────────────────────────────────
class _CodigoTile extends StatelessWidget {
  final Map<String, dynamic> codigo;
  final VoidCallback onEliminar;
  const _CodigoTile({required this.codigo, required this.onEliminar});

  String _badge() {
    final tipo = codigo['tipo'] as String;
    final valor = (codigo['valor'] as num).toDouble();
    return tipo == 'porcentaje'
        ? '${valor.toStringAsFixed(0)}% OFF'
        : '\$${valor.toStringAsFixed(0)} OFF';
  }

  @override
  Widget build(BuildContext context) {
    final activo = codigo['activo'] as bool;
    final usos = codigo['usosActuales'] as int;
    final maxUsos = codigo['usosMaximos'];
    final expiracion = codigo['fechaExpiracion'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.sand),
        color: activo ? AppColors.cream : AppColors.beige,
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined, size: 20, color: AppColors.charcoal),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(codigo['codigo'],
                      style: GoogleFonts.syne(
                        fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      color: AppColors.ink,
                      child: Text(_badge(),
                        style: GoogleFonts.dmMono(fontSize: 9, color: AppColors.cream, letterSpacing: 0.1),
                      ),
                    ),
                    if (!activo) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        color: AppColors.stone,
                        child: Text('INACTIVO',
                          style: GoogleFonts.dmMono(fontSize: 9, color: AppColors.cream, letterSpacing: 0.1),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  [
                    'Usos: $usos${maxUsos != null ? ' / $maxUsos' : ''}',
                    if (expiracion != null) 'Expira: ${_formatFecha(expiracion)}',
                  ].join('  ·  '),
                  style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.stone),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEliminar,
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.stone),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  String _formatFecha(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── DIALOG CREAR ──────────────────────────────────────────
class _CrearCodigoDialog extends StatefulWidget {
  final VoidCallback onCreado;
  const _CrearCodigoDialog({required this.onCreado});

  @override
  State<_CrearCodigoDialog> createState() => _CrearCodigoDialogState();
}

class _CrearCodigoDialogState extends State<_CrearCodigoDialog> {
  final _codigoCtrl = TextEditingController();
  final _valorCtrl  = TextEditingController();
  final _usosCtrl   = TextEditingController();
  String _tipo = 'porcentaje';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codigoCtrl.dispose();
    _valorCtrl.dispose();
    _usosCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    final codigo = _codigoCtrl.text.trim().toUpperCase();
    final valorStr = _valorCtrl.text.trim();
    final usosStr = _usosCtrl.text.trim();

    if (codigo.isEmpty || valorStr.isEmpty) {
      setState(() => _error = 'Completá el código y el valor.');
      return;
    }
    final valor = double.tryParse(valorStr.replaceAll('%', '').replaceAll('\$', '').trim());
    if (valor == null || valor <= 0) {
      setState(() => _error = 'El valor debe ser un número positivo.');
      return;
    }
    if (_tipo == 'porcentaje' && valor > 100) {
      setState(() => _error = 'El porcentaje no puede superar 100.');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await context.read<ApiService>().crearCodigoPromocion(
        codigo: codigo,
        tipo: _tipo,
        valor: valor,
        usosMaximos: usosStr.isNotEmpty ? int.tryParse(usosStr) : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onCreado();
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nuevo código',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 24),

              AuthField(label: 'CÓDIGO', controller: _codigoCtrl, hint: 'Ej: VERANO20'),
              const SizedBox(height: 16),

              // Tipo
              Text('TIPO DE DESCUENTO',
                style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.gray, letterSpacing: 0.15)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _TipoBtn(label: 'Porcentaje (%)', selected: _tipo == 'porcentaje',
                    onTap: () => setState(() => _tipo = 'porcentaje')),
                  const SizedBox(width: 8),
                  _TipoBtn(label: 'Monto fijo (\$)', selected: _tipo == 'fijo',
                    onTap: () => setState(() => _tipo = 'fijo')),
                ],
              ),
              const SizedBox(height: 16),

              AuthField(
                label: _tipo == 'porcentaje' ? 'PORCENTAJE (0–100)' : 'MONTO EN PESOS',
                controller: _valorCtrl,
                hint: _tipo == 'porcentaje' ? '10' : '5000',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              AuthField(
                label: 'USOS MÁXIMOS (opcional)',
                controller: _usosCtrl,
                hint: 'Dejar vacío = ilimitado',
                keyboardType: TextInputType.number,
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                ErrorMsg(_error!),
              ],

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancelar',
                      style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone)),
                  ),
                  const SizedBox(width: 8),
                  PrimaryButton(label: 'Crear', loading: _loading, onPressed: _crear),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipoBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TipoBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.cream,
          border: Border.all(color: selected ? AppColors.ink : AppColors.sand),
        ),
        child: Text(label,
          style: GoogleFonts.dmMono(
            fontSize: 11,
            color: selected ? AppColors.cream : AppColors.charcoal,
          ),
        ),
      ),
    );
  }
}
