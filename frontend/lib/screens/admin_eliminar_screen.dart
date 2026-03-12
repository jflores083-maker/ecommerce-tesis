import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AdminEliminarScreen extends StatefulWidget {
  const AdminEliminarScreen({super.key});

  @override
  State<AdminEliminarScreen> createState() => _AdminEliminarScreenState();
}

class _AdminEliminarScreenState extends State<AdminEliminarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().cargarMisProductos();
    });
  }

  Future<void> _confirmarEliminar(Producto p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: Text('Eliminar producto',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22, fontWeight: FontWeight.w300, color: AppColors.ink,
          ),
        ),
        content: Text('¿Dar de baja "${p.titulo}"? No aparecerá más en la tienda.',
          style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.gray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: AppColors.cream,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              elevation: 0,
            ),
            child: Text('Eliminar', style: GoogleFonts.dmMono(fontSize: 11)),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final admin = context.read<AdminProvider>();
    final success = await admin.eliminarProducto(p.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          success ? '✓ "${p.titulo}" eliminado' : admin.error ?? 'Error al eliminar',
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream),
        ),
        backgroundColor: success ? AppColors.ink : AppColors.charcoal,
        behavior: SnackBarBehavior.floating,
      ));
    }
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Eliminar producto',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 40, fontWeight: FontWeight.w300, color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Seleccioná el producto que querés dar de baja.',
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
                  ...admin.misProductos.map((p) => _ProductoEliminarRow(
                    producto: p,
                    onEliminar: () => _confirmarEliminar(p),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductoEliminarRow extends StatelessWidget {
  final Producto producto;
  final VoidCallback onEliminar;
  const _ProductoEliminarRow({required this.producto, required this.onEliminar});

  @override
  Widget build(BuildContext context) {
    final url = producto.imagenPrincipalUrl;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              // Thumbnail
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
                    Text(producto.categoria.toUpperCase(),
                      style: GoogleFonts.dmMono(fontSize: 10, color: AppColors.stone, letterSpacing: 0.1),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEliminar,
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Eliminar',
              ),
            ],
          ),
        ),
        const Divider(color: AppColors.sand, height: 1, thickness: 1),
      ],
    );
  }
}
