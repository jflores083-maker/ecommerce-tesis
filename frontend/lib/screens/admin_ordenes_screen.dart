import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AdminOrdenesScreen extends StatefulWidget {
  const AdminOrdenesScreen({super.key});

  @override
  State<AdminOrdenesScreen> createState() => _AdminOrdenesScreenState();
}

class _AdminOrdenesScreenState extends State<AdminOrdenesScreen> {
  final _api = ApiService();
  List<dynamic> _ordenes = [];
  bool _loading = true;
  String? _filtroEstado; // null = todos

  static const _estados = [
    'pendiente',
    'pagado',
    'enviado',
    'entregado',
    'cancelado'
  ];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getTodasOrdenes(estado: _filtroEstado);
      if (mounted) {
        setState(() {
          _ordenes = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar órdenes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: const AppNavBar(),
      body: RefreshIndicator(
        onRefresh: _cargar,
        color: AppColors.ink,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 48,
            vertical: 48,
          ),
          child: Center(
            child: SizedBox(
              width: 900,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panel de órdenes',
                    style: GoogleFonts.syne(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gestión de pedidos de clientes.',
                    style: GoogleFonts.dmMono(
                        fontSize: 11, color: AppColors.charcoal),
                  ),
                  const SizedBox(height: 32),

                  // Filtro chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FiltroChip(
                          label: 'Todos',
                          selected: _filtroEstado == null,
                          onTap: () {
                            setState(() => _filtroEstado = null);
                            _cargar();
                          },
                        ),
                        const SizedBox(width: 8),
                        ..._estados.map((e) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _FiltroChip(
                                label: _estadoLabel(e),
                                selected: _filtroEstado == e,
                                onTap: () {
                                  setState(() => _filtroEstado = e);
                                  _cargar();
                                },
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (_loading)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(),
                    ))
                  else if (_ordenes.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48),
                        child: Text(
                          'No hay órdenes.',
                          style: GoogleFonts.dmMono(
                              fontSize: 13, color: AppColors.stone),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _ordenes
                          .map((o) => _OrdenCard(
                                orden: o,
                                onEstadoCambiado: _cargar,
                                api: _api,
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Chip de filtro ────────────────────────────────────────

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.ink;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c : Colors.transparent,
          border: Border.all(color: selected ? c : AppColors.sand),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmMono(
            fontSize: 11,
            color: selected ? Colors.white : AppColors.stone,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Tarjeta de orden ──────────────────────────────────────

class _OrdenCard extends StatefulWidget {
  final dynamic orden;
  final VoidCallback onEstadoCambiado;
  final ApiService api;

  const _OrdenCard({
    required this.orden,
    required this.onEstadoCambiado,
    required this.api,
  });

  @override
  State<_OrdenCard> createState() => _OrdenCardState();
}

class _OrdenCardState extends State<_OrdenCard> {
  bool _expanded = false;
  bool _loadingEstado = false;

  String _fmt(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  Future<void> _cambiarEstado(String nuevoEstado, {String? seguimiento}) async {
    setState(() => _loadingEstado = true);
    try {
      await widget.api.actualizarEstadoOrden(
        widget.orden['ordenId'] as int,
        nuevoEstado,
        numeroSeguimiento: seguimiento,
      );
      widget.onEstadoCambiado();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _loadingEstado = false);
      }
    }
  }

  void _mostrarDialogoEstado() {
    final estadoActual = widget.orden['estado'] as String;
    final nextEstados = _siguientesEstados(estadoActual);
    if (nextEstados.isEmpty) return;

    final seguimientoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: Text(
          'Cambiar estado',
          style: GoogleFonts.syne(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        content: StatefulBuilder(
          builder: (ctx, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Orden #${widget.orden['ordenId']} — actual: ${_estadoLabel(estadoActual)}',
                style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
              ),
              const SizedBox(height: 20),
              ...nextEstados.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        if (e == 'enviado') {
                          _pedirSeguimiento(e, seguimientoCtrl);
                        } else {
                          _cambiarEstado(e);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: _estadoColor(e)),
                          color: _estadoColor(e).withOpacity(0.07),
                        ),
                        child: Text(
                          _estadoLabel(e),
                          style: GoogleFonts.syne(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _estadoColor(e),
                          ),
                        ),
                      ),
                    ),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone),
            ),
          ),
        ],
      ),
    );
  }

  void _pedirSeguimiento(String estado, TextEditingController ctrl) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: Text(
          'Número de seguimiento',
          style: GoogleFonts.syne(
              fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Opcional. Ingresá el número de seguimiento del envío.',
              style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'Ej: AR123456789',
                hintStyle:
                    GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone),
                border: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.sand)),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.ink)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: GoogleFonts.dmMono(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cambiarEstado(estado,
                  seguimiento:
                      ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
            },
            child: Text(
              'Confirmar',
              style: GoogleFonts.dmMono(
                  fontSize: 12,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.orden;
    final estado = o['estado'] as String;
    final items = (o['items'] as List?) ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.sand),
        color: AppColors.cream,
      ),
      child: Column(
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // ID + fecha
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orden #${o['ordenId']}',
                          style: GoogleFonts.syne(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatFecha(o['fecha'] as String),
                          style: GoogleFonts.dmMono(
                              fontSize: 10, color: AppColors.stone),
                        ),
                      ],
                    ),
                  ),
                  // Comprador
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          o['compradorNombre'] ?? '',
                          style: GoogleFonts.dmMono(
                              fontSize: 12, color: AppColors.ink),
                        ),
                        Text(
                          o['compradorEmail'] ?? '',
                          style: GoogleFonts.dmMono(
                              fontSize: 10, color: AppColors.stone),
                        ),
                      ],
                    ),
                  ),
                  // Total
                  Text(
                    _fmt((o['total'] as num).toDouble()),
                    style: GoogleFonts.syne(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Estado badge
                  _EstadoBadge(estado: estado),
                  const SizedBox(width: 12),
                  // Cambiar estado btn
                  if (_loadingEstado)
                    const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else if (_siguientesEstados(estado).isNotEmpty)
                    GestureDetector(
                      onTap: _mostrarDialogoEstado,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.ink),
                        ),
                        child: Text(
                          'Cambiar',
                          style: GoogleFonts.dmMono(
                              fontSize: 10,
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.stone,
                  ),
                ],
              ),
            ),
          ),

          // Detalle expandido
          if (_expanded) ...[
            const Divider(color: AppColors.sand, height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dirección
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.stone),
                      const SizedBox(width: 6),
                      Text(
                        '${o['direccionEnvio']}, ${o['ciudad']} (${o['codigoPostal']})',
                        style: GoogleFonts.dmMono(
                            fontSize: 11, color: AppColors.stone),
                      ),
                    ],
                  ),
                  if (o['numeroSeguimiento'] != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined,
                            size: 14, color: AppColors.stone),
                        const SizedBox(width: 6),
                        Text(
                          'Seguimiento: ${o['numeroSeguimiento']}',
                          style: GoogleFonts.dmMono(
                              fontSize: 11, color: AppColors.stone),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Items
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item['titulo']} — talle ${item['talle']}',
                                style: GoogleFonts.dmMono(
                                    fontSize: 12, color: AppColors.ink),
                              ),
                            ),
                            Text(
                              '${item['cantidad']}x  ${_fmt((item['precioUnitario'] as num).toDouble())}',
                              style: GoogleFonts.dmMono(
                                  fontSize: 12, color: AppColors.stone),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.sand, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _TotalRow(
                              label: 'Subtotal',
                              valor: _fmt((o['subtotal'] as num).toDouble())),
                          _TotalRow(
                              label: 'Envío',
                              valor: _fmt((o['costoEnvio'] as num).toDouble())),
                          _TotalRow(
                            label: 'Total',
                            valor: _fmt((o['total'] as num).toDouble()),
                            bold: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String valor;
  final bool bold;
  const _TotalRow(
      {required this.label, required this.valor, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.dmMono(
              fontSize: 12,
              color: AppColors.stone,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            valor,
            style: GoogleFonts.dmMono(
              fontSize: 12,
              color: AppColors.ink,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = _estadoColor(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        _estadoLabel(estado),
        style: GoogleFonts.dmMono(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Helpers globales ──────────────────────────────────────

String _estadoLabel(String e) {
  switch (e) {
    case 'pendiente':
      return 'PENDIENTE';
    case 'pagado':
      return 'PAGADO';
    case 'enviado':
      return 'ENVIADO';
    case 'entregado':
      return 'ENTREGADO';
    case 'cancelado':
      return 'CANCELADO';
    default:
      return e.toUpperCase();
  }
}

Color _estadoColor(String e) {
  switch (e) {
    case 'pendiente':
      return const Color(0xFFB45309);
    case 'pagado':
      return const Color(0xFF2563EB);
    case 'enviado':
      return const Color(0xFF7C3AED);
    case 'entregado':
      return const Color(0xFF16A34A);
    case 'cancelado':
      return const Color(0xFFDC2626);
    default:
      return AppColors.stone;
  }
}

List<String> _siguientesEstados(String actual) {
  switch (actual) {
    case 'pendiente':
      return ['pagado', 'cancelado'];
    case 'pagado':
      return ['enviado', 'cancelado'];
    case 'enviado':
      return ['entregado', 'cancelado'];
    default:
      return [];
  }
}

String _formatFecha(String iso) {
  try {
    final d = DateTime.parse(iso).toLocal();
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return iso;
  }
}
