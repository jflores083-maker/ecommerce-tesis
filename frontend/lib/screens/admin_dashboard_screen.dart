import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _data;
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
      final res = await context.read<ApiService>().getDashboard();
      setState(() { _data = res; _cargando = false; });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _cargando = false; });
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
        child: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppColors.charcoal))
            : _error != null
                ? Center(child: ErrorMsg(_error!))
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : 48, vertical: 40,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 900,
                        child: _DashboardBody(data: _data!, isMobile: isMobile),
                      ),
                    ),
                  ),
      ),
    );
  }
}

// ─── BODY ──────────────────────────────────────────────────
class _DashboardBody extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isMobile;
  const _DashboardBody({required this.data, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final ventas    = data['totalVentas'] as num;
    final ordenes   = data['totalOrdenes'] as int;
    final hoy       = data['ordenesHoy'] as int;
    final productos = data['productosActivos'] as int;
    final ventasMes = (data['ventasPorMes'] as List).cast<Map<String, dynamic>>();
    final recientes = (data['ordenesRecientes'] as List).cast<Map<String, dynamic>>();
    final top       = data['productoTop'] as Map<String, dynamic>?;
    final bajoStock = (data['productosBajoStock'] as List).cast<Map<String, dynamic>>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Text('Dashboard',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 40, fontWeight: FontWeight.w600, color: AppColors.ink,
          ),
        ),
        Text('Resumen general de tu tienda.',
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone)),
        const SizedBox(height: 36),

        // ── Tarjetas resumen ──────────────────────────────────
        isMobile
            ? Column(children: _tarjetas(ventas, ordenes, hoy, productos))
            : Row(children: _tarjetasRow(ventas, ordenes, hoy, productos)),
        const SizedBox(height: 36),

        // ── Gráfico barras ────────────────────────────────────
        _Seccion(
          titulo: 'Ventas últimos 6 meses',
          child: _GraficoBarras(meses: ventasMes),
        ),
        const SizedBox(height: 28),

        // ── Fila: producto top + bajo stock ───────────────────
        isMobile
            ? Column(
                children: [
                  if (top != null) _Seccion(titulo: 'Más vendido', child: _ProductoTop(top: top)),
                  const SizedBox(height: 28),
                  _Seccion(titulo: 'Stock bajo', child: _BajoStock(items: bajoStock)),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (top != null)
                    Expanded(child: _Seccion(titulo: 'Más vendido', child: _ProductoTop(top: top))),
                  if (top != null) const SizedBox(width: 20),
                  Expanded(child: _Seccion(titulo: 'Stock bajo', child: _BajoStock(items: bajoStock))),
                ],
              ),
        const SizedBox(height: 28),

        // ── Órdenes recientes ─────────────────────────────────
        _Seccion(
          titulo: 'Órdenes recientes',
          child: _OrdenesRecientes(ordenes: recientes),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  List<Widget> _tarjetas(num ventas, int ordenes, int hoy, int productos) => [
    _Tarjeta(titulo: 'VENTAS TOTALES', valor: _formatPrecio(ventas.toDouble()),
        icono: Icons.attach_money, color: AppColors.ink),
    const SizedBox(height: 12),
    _Tarjeta(titulo: 'ÓRDENES', valor: '$ordenes',
        icono: Icons.receipt_long_outlined, color: AppColors.charcoal),
    const SizedBox(height: 12),
    _Tarjeta(titulo: 'ÓRDENES HOY', valor: '$hoy',
        icono: Icons.today_outlined, color: AppColors.charcoal),
    const SizedBox(height: 12),
    _Tarjeta(titulo: 'PRODUCTOS ACTIVOS', valor: '$productos',
        icono: Icons.inventory_2_outlined, color: AppColors.charcoal),
  ];

  List<Widget> _tarjetasRow(num ventas, int ordenes, int hoy, int productos) => [
    Expanded(child: _Tarjeta(titulo: 'VENTAS TOTALES', valor: _formatPrecio(ventas.toDouble()),
        icono: Icons.attach_money, color: AppColors.ink)),
    const SizedBox(width: 12),
    Expanded(child: _Tarjeta(titulo: 'ÓRDENES', valor: '$ordenes',
        icono: Icons.receipt_long_outlined, color: AppColors.charcoal)),
    const SizedBox(width: 12),
    Expanded(child: _Tarjeta(titulo: 'ÓRDENES HOY', valor: '$hoy',
        icono: Icons.today_outlined, color: AppColors.charcoal)),
    const SizedBox(width: 12),
    Expanded(child: _Tarjeta(titulo: 'PRODUCTOS ACTIVOS', valor: '$productos',
        icono: Icons.inventory_2_outlined, color: AppColors.charcoal)),
  ];

  static String _formatPrecio(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';
}

// ─── TARJETA MÉTRICA ───────────────────────────────────────
class _Tarjeta extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;
  const _Tarjeta({required this.titulo, required this.valor, required this.icono, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border.all(color: AppColors.sand),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.beige, borderRadius: BorderRadius.circular(4)),
            child: Icon(icono, size: 22, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                  style: GoogleFonts.dmMono(fontSize: 9, color: AppColors.stone, letterSpacing: 0.12)),
                const SizedBox(height: 4),
                Text(valor,
                  style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SECCIÓN CON TÍTULO ────────────────────────────────────
class _Seccion extends StatelessWidget {
  final String titulo;
  final Widget child;
  const _Seccion({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo.toUpperCase(),
          style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.stone, letterSpacing: 0.15)),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

// ─── GRÁFICO DE BARRAS ─────────────────────────────────────
class _GraficoBarras extends StatelessWidget {
  final List<Map<String, dynamic>> meses;
  const _GraficoBarras({required this.meses});

  @override
  Widget build(BuildContext context) {
    final maxVal = meses.map((m) => (m['total'] as num).toDouble()).fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border.all(color: AppColors.sand),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: meses.map((m) {
                final val = (m['total'] as num).toDouble();
                final ratio = maxVal > 0 ? val / maxVal : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              val >= 1000
                                  ? '\$${(val / 1000).toStringAsFixed(0)}k'
                                  : '\$${val.toStringAsFixed(0)}',
                              style: GoogleFonts.dmMono(fontSize: 8, color: AppColors.stone),
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: ratio * 110,
                          decoration: BoxDecoration(
                            color: val > 0 ? AppColors.ink : AppColors.sand,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: meses.map((m) => Expanded(
              child: Center(
                child: Text(m['mesNombre'] as String,
                  style: GoogleFonts.dmMono(fontSize: 9, color: AppColors.stone)),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

// ─── PRODUCTO TOP ──────────────────────────────────────────
class _ProductoTop extends StatelessWidget {
  final Map<String, dynamic> top;
  const _ProductoTop({required this.top});

  @override
  Widget build(BuildContext context) {
    final total = (top['totalGenerado'] as num).toDouble();
    final totalFmt = '\$${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

    return GestureDetector(
      onTap: () => context.go('/producto/${top['id']}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cream,
          border: Border.all(color: AppColors.sand),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(4)),
              child: const Icon(Icons.emoji_events_outlined, size: 22, color: AppColors.cream),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(top['titulo'] as String,
                    style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('${top['unidadesVendidas']} uds · $totalFmt',
                    style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.stone)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.stone),
          ],
        ),
      ),
    );
  }
}

// ─── BAJO STOCK ────────────────────────────────────────────
class _BajoStock extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _BajoStock({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.cream, border: Border.all(color: AppColors.sand)),
        child: Text('Todos los productos tienen stock suficiente.',
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone)),
      );
    }

    return Container(
      decoration: BoxDecoration(color: AppColors.cream, border: Border.all(color: AppColors.sand)),
      child: Column(
        children: items.map((p) {
          final stock = p['stock'] as int;
          final critico = stock == 0;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.sand)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: critico ? Colors.red : Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(p['titulo'] as String,
                    style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.ink),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text(critico ? 'AGOTADO' : '$stock ud${stock != 1 ? 's' : ''}',
                  style: GoogleFonts.dmMono(
                    fontSize: 10,
                    color: critico ? Colors.red : Colors.orange.shade800,
                    fontWeight: FontWeight.w700,
                  )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── ÓRDENES RECIENTES ─────────────────────────────────────
class _OrdenesRecientes extends StatelessWidget {
  final List<Map<String, dynamic>> ordenes;
  const _OrdenesRecientes({required this.ordenes});

  static const _colores = {
    'pendiente':  Color(0xFFFFA500),
    'pagado':     Color(0xFF4CAF50),
    'enviado':    Color(0xFF2196F3),
    'entregado':  Color(0xFF4CAF50),
    'cancelado':  Color(0xFFE53935),
  };

  static String _formatPrecio(double v) =>
      '\$${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}';

  @override
  Widget build(BuildContext context) {
    if (ordenes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.cream, border: Border.all(color: AppColors.sand)),
        child: Text('No hay órdenes todavía.',
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone)),
      );
    }

    return Container(
      decoration: BoxDecoration(color: AppColors.cream, border: Border.all(color: AppColors.sand)),
      child: Column(
        children: ordenes.map((o) {
          final estado  = o['estado'] as String;
          final total   = (o['total'] as num).toDouble();
          final fecha   = DateTime.parse(o['fecha'] as String);
          final color   = _colores[estado] ?? AppColors.stone;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.sand)),
            ),
            child: Row(
              children: [
                Text('#${o['ordenId']}',
                  style: GoogleFonts.dmMono(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.ink)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(estado.toUpperCase(),
                    style: GoogleFonts.dmMono(fontSize: 9, color: color, fontWeight: FontWeight.w700, letterSpacing: 0.1)),
                ),
                const Spacer(),
                Text('${fecha.day}/${fecha.month}/${fecha.year}',
                  style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.stone)),
                const SizedBox(width: 16),
                Text(_formatPrecio(total),
                  style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
