import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/drops_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class DropDetalleScreen extends StatefulWidget {
  final int dropId;
  const DropDetalleScreen({super.key, required this.dropId});

  @override
  State<DropDetalleScreen> createState() => _DropDetalleScreenState();
}

class _DropDetalleScreenState extends State<DropDetalleScreen> {
  DropDetalle? _drop;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final data = await context.read<DropsProvider>().getDetalle(widget.dropId);
    if (mounted) setState(() { _drop = data; _cargando = false; });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: const AppNavBar(),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppColors.charcoal))
          : _drop == null
              ? Center(
                  child: Text('Drop no encontrado.',
                    style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.stone),
                  ),
                )
              : _buildContent(isMobile),
    );
  }

  Widget _buildContent(bool isMobile) {
    final drop = _drop!;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero del drop ──
          SizedBox(
            height: isMobile ? 280 : 420,
            child: Stack(
              fit: StackFit.expand,
              children: [
                drop.imagenUrl != null
                    ? Image.network(
                        '${ApiService.serverUrl}${drop.imagenUrl}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: AppColors.ink),
                      )
                    : Container(color: AppColors.ink),
                // Gradiente inferior
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.ink.withValues(alpha: 0.8),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                // Texto sobre el hero
                Positioned(
                  bottom: 32, left: isMobile ? 24 : 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(drop.nombre,
                        style: GoogleFonts.syne(
                          fontSize: isMobile ? 36 : 56,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cream,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${drop.productos.length} piezas · ${_fechaFormateada(drop.fechaCreacion)}',
                        style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Productos ──
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 80,
              vertical: 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PIEZAS DEL DROP',
                  style: GoogleFonts.dmMono(
                    fontSize: 10, color: AppColors.gray, letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 24),
                drop.productos.isEmpty
                    ? Text('Este drop no tiene productos asignados.',
                        style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.stone),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 2 : 4,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.55,
                        ),
                        itemCount: drop.productos.length,
                        itemBuilder: (_, i) => _DropProductoCard(item: drop.productos[i]),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fechaFormateada(DateTime d) {
    const meses = ['ene','feb','mar','abr','may','jun','jul','ago','sep','oct','nov','dic'];
    return '${d.day} ${meses[d.month - 1]} ${d.year}';
  }
}

class _DropProductoCard extends StatefulWidget {
  final DropProductoItem item;
  const _DropProductoCard({required this.item});

  @override
  State<_DropProductoCard> createState() => _DropProductoCardState();
}

class _DropProductoCardState extends State<_DropProductoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final disponible = item.estado == 'disponible';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/producto/${item.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  item.imagenUrl != null
                      ? Image.network(
                          '${ApiService.serverUrl}${item.imagenUrl}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: AppColors.sand),
                        )
                      : Container(color: AppColors.sand),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    color: _hovered ? AppColors.ink.withValues(alpha: 0.2) : Colors.transparent,
                  ),
                  if (!disponible)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        color: AppColors.charcoal,
                        child: Text('SIN STOCK',
                          style: GoogleFonts.dmMono(
                            fontSize: 8, color: AppColors.cream, fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(item.titulo,
              style: GoogleFonts.syne(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(item.precioFormateado,
              style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.charcoal),
            ),
          ],
        ),
      ),
    );
  }
}
