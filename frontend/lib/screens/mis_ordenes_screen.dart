import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class MisOrdenesScreen extends StatefulWidget {
  const MisOrdenesScreen({super.key});

  @override
  State<MisOrdenesScreen> createState() => _MisOrdenesScreenState();
}

class _MisOrdenesScreenState extends State<MisOrdenesScreen> {
  List<dynamic> _ordenes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<ApiService>();
      final data = await api.getHistorialOrdenes();
      if (mounted) setState(() { _ordenes = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'No se pudo cargar el historial'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const AppNavBar(),
      body: RefreshIndicator(
        color: AppColors.ink,
        backgroundColor: AppColors.cream,
        onRefresh: _cargar,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.charcoal))
            : _error != null
                ? Center(
                    child: Text(_error!,
                        style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone)))
                : _ordenes.isEmpty
                    ? _EmptyOrdenes()
                    : _ListaOrdenes(ordenes: _ordenes),
      ),
    );
  }
}

class _EmptyOrdenes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: AppColors.stone.withOpacity(0.3)),
          const SizedBox(height: 24),
          Text('Todavía no realizaste ningún pedido',
              style: GoogleFonts.syne(
                  fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 8),
          Text('Tus órdenes aparecerán acá una vez que compres.',
              style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone)),
        ],
      ),
    );
  }
}

class _ListaOrdenes extends StatelessWidget {
  final List<dynamic> ordenes;
  const _ListaOrdenes({required this.ordenes});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mis órdenes',
                  style: GoogleFonts.syne(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              const SizedBox(height: 8),
              Text('${ordenes.length} ${ordenes.length == 1 ? 'pedido' : 'pedidos'}',
                  style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone)),
              const SizedBox(height: 32),
              ...ordenes.map((o) => _OrdenCard(resumen: o as Map<String, dynamic>)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── CARD DE ORDEN ─────────────────────────────────────────
class _OrdenCard extends StatefulWidget {
  final Map<String, dynamic> resumen;
  const _OrdenCard({required this.resumen});

  @override
  State<_OrdenCard> createState() => _OrdenCardState();
}

class _OrdenCardState extends State<_OrdenCard> {
  bool _expandido = false;
  Map<String, dynamic>? _detalle;
  bool _cargandoDetalle = false;

  Future<void> _toggleDetalle() async {
    if (_expandido) {
      setState(() => _expandido = false);
      return;
    }
    setState(() { _expandido = true; _cargandoDetalle = _detalle == null; });
    if (_detalle == null) {
      try {
        final api = context.read<ApiService>();
        final data = await api.getDetalleOrden(widget.resumen['ordenId'] as int);
        if (mounted) setState(() { _detalle = data; _cargandoDetalle = false; });
      } catch (_) {
        if (mounted) setState(() => _cargandoDetalle = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.resumen;
    final ordenId = o['ordenId'] as int;
    final estado = o['estado'] as String;
    final total = (o['total'] as num).toDouble();
    final fecha = DateTime.tryParse(o['fecha'] as String? ?? '') ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.beige,
        border: Border.all(color: AppColors.sand),
      ),
      child: Column(
        children: [
          // ── Cabecera ──────────────────────────────────────
          InkWell(
            onTap: _toggleDetalle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Orden #$ordenId',
                                style: GoogleFonts.syne(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink)),
                            const SizedBox(width: 10),
                            _EstadoBadge(estado: estado),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatFecha(fecha),
                          style: GoogleFonts.dmMono(
                              fontSize: 10, color: AppColors.stone),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatPrecio(total),
                    style: GoogleFonts.syne(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expandido ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down,
                        size: 20, color: AppColors.stone),
                  ),
                ],
              ),
            ),
          ),

          // ── Detalle expandible ────────────────────────────
          if (_expandido)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.sand)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: _cargandoDetalle
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.ink),
                      ))
                  : _detalle == null
                      ? Text('No se pudo cargar el detalle',
                          style: GoogleFonts.dmMono(
                              fontSize: 11, color: AppColors.stone))
                      : _DetalleOrden(detalle: _detalle!),
            ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime d) {
    const meses = [
      '', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
    ];
    return '${d.day} ${meses[d.month]} ${d.year}';
  }

  String _formatPrecio(double v) {
    final parts = <String>[];
    final s = v.toStringAsFixed(0);
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) parts.add('.');
      parts.add(s[i]);
    }
    return '\$${parts.join()}';
  }
}

// ─── DETALLE EXPANDIDO ─────────────────────────────────────
class _DetalleOrden extends StatelessWidget {
  final Map<String, dynamic> detalle;
  const _DetalleOrden({required this.detalle});

  @override
  Widget build(BuildContext context) {
    final items = (detalle['items'] as List?) ?? [];
    final direccion = detalle['direccionEnvio'] as String? ?? '';
    final ciudad = detalle['ciudad'] as String? ?? '';
    final cp = detalle['codigoPostal'] as String? ?? '';
    final tracking = detalle['numeroSeguimiento'] as String?;
    final subtotal = (detalle['subtotal'] as num).toDouble();
    final envio = (detalle['costoEnvio'] as num).toDouble();
    final total = (detalle['total'] as num).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Items
        ...items.map((item) => _ItemRow(item: item as Map<String, dynamic>)),
        const SizedBox(height: 16),
        const Divider(color: AppColors.sand, height: 1),
        const SizedBox(height: 16),

        // Totales
        _SummaryRow(label: 'Subtotal', value: _fmt(subtotal)),
        _SummaryRow(
            label: 'Envío',
            value: envio == 0 ? 'Gratis' : _fmt(envio)),
        _SummaryRow(label: 'Total', value: _fmt(total), bold: true),
        const SizedBox(height: 16),
        const Divider(color: AppColors.sand, height: 1),
        const SizedBox(height: 16),

        // Dirección
        Text('ENVÍO A',
            style: GoogleFonts.dmMono(
                fontSize: 10, color: AppColors.gray, letterSpacing: 0.12)),
        const SizedBox(height: 6),
        Text('$direccion, $ciudad ($cp)',
            style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.charcoal)),

        // Número de seguimiento
        if (tracking != null && tracking.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text('NÚMERO DE SEGUIMIENTO',
              style: GoogleFonts.dmMono(
                  fontSize: 10, color: AppColors.gray, letterSpacing: 0.12)),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.sand),
              color: AppColors.cream,
            ),
            child: Text(tracking,
                style: GoogleFonts.dmMono(
                    fontSize: 12, color: AppColors.charcoal)),
          ),
        ],
      ],
    );
  }

  String _fmt(double v) {
    final parts = <String>[];
    final s = v.toStringAsFixed(0);
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) parts.add('.');
      parts.add(s[i]);
    }
    return '\$${parts.join()}';
  }
}

class _ItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final titulo = item['titulo'] as String? ?? '';
    final talle = item['talle'] as String? ?? '';
    final cantidad = item['cantidad'] as int? ?? 1;
    final precio = (item['precioUnitario'] as num).toDouble();
    final imagenUrl = item['imagenUrl'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: 60,
            height: 76,
            color: AppColors.beige,
            child: imagenUrl != null && imagenUrl.isNotEmpty
                ? Image.network(
                    '${ApiService.serverUrl}$imagenUrl',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox(),
                  )
                : const Icon(Icons.shopping_bag_outlined,
                    size: 24, color: AppColors.stone),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('TALLE ${talle.toUpperCase()} · x$cantidad',
                    style: GoogleFonts.dmMono(
                        fontSize: 10, color: AppColors.stone)),
              ],
            ),
          ),
          Text(
            _fmt(precio * cantidad),
            style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.charcoal),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    final parts = <String>[];
    final s = v.toStringAsFixed(0);
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) parts.add('.');
      parts.add(s[i]);
    }
    return '\$${parts.join()}';
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _SummaryRow(
      {required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.dmMono(
                  fontSize: 10,
                  color: bold ? AppColors.ink : AppColors.gray,
                  fontWeight:
                      bold ? FontWeight.w700 : FontWeight.normal,
                  letterSpacing: 0.08)),
          Text(value,
              style: GoogleFonts.dmMono(
                  fontSize: bold ? 13 : 11,
                  color: AppColors.charcoal,
                  fontWeight:
                      bold ? FontWeight.w700 : FontWeight.normal)),
        ],
      ),
    );
  }
}

// ─── BADGE DE ESTADO ───────────────────────────────────────
class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (estado) {
      'pendiente' => (AppColors.stone, AppColors.sand),
      'pagado' => (const Color(0xFF1565C0), const Color(0xFFE3F2FD)),
      'enviado' => (const Color(0xFFE65100), const Color(0xFFFFF3E0)),
      'entregado' => (const Color(0xFF2E7D32), const Color(0xFFE8F5E9)),
      'cancelado' => (const Color(0xFFC62828), const Color(0xFFFFEBEE)),
      _ => (AppColors.stone, AppColors.sand),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        estado.toUpperCase(),
        style: GoogleFonts.dmMono(
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1),
      ),
    );
  }
}
