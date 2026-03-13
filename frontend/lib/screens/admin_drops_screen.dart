import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/drops_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AdminDropsScreen extends StatefulWidget {
  const AdminDropsScreen({super.key});

  @override
  State<AdminDropsScreen> createState() => _AdminDropsScreenState();
}

class _AdminDropsScreenState extends State<AdminDropsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DropsProvider>().cargarDrops();
    });
  }

  Future<void> _eliminar(Drop drop) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: Text('Eliminar drop',
          style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        content: Text('¿Eliminás "${drop.nombre}"? Esta acción no se puede deshacer.',
          style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.charcoal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Eliminar', style: GoogleFonts.dmMono(fontSize: 12, color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<DropsProvider>().eliminarDrop(drop.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final provider = context.watch<DropsProvider>();

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
                Text('Drops',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 40, fontWeight: FontWeight.w500, color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Lanzamientos exclusivos de la tienda.',
                  style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go('/admin/drops/nuevo'),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('Nuevo drop',
                      style: GoogleFonts.dmMono(fontSize: 12, letterSpacing: 0.1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.cream,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (provider.cargando)
                  const Center(child: CircularProgressIndicator(color: AppColors.charcoal))
                else if (provider.drops.isEmpty)
                  Text('No hay drops creados todavía.',
                    style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone),
                  )
                else
                  ...provider.drops.map((drop) => _DropListItem(
                    drop: drop,
                    onEditar: () => context.go('/admin/drops/${drop.id}/editar'),
                    onEliminar: () => _eliminar(drop),
                    onVer: () => context.go('/drops/${drop.id}'),
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropListItem extends StatelessWidget {
  final Drop drop;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;
  final VoidCallback onVer;

  const _DropListItem({required this.drop, required this.onEditar, required this.onEliminar, required this.onVer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.sand),
        color: AppColors.cream,
      ),
      child: Row(
        children: [
          // Miniatura
          SizedBox(
            width: 80, height: 80,
            child: drop.imagenUrl != null
                ? Image.network(
                    '${ApiService.serverUrl}${drop.imagenUrl}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.sand),
                  )
                : Container(
                    color: AppColors.sand,
                    child: const Icon(Icons.bolt_outlined, color: AppColors.stone),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(drop.nombre,
                  style: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text('${drop.totalProductos} productos',
                  style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new, size: 18, color: AppColors.charcoal),
            tooltip: 'Ver drop',
            onPressed: onVer,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.charcoal),
            tooltip: 'Editar',
            onPressed: onEditar,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.charcoal),
            tooltip: 'Eliminar',
            onPressed: onEliminar,
          ),
        ],
      ),
    );
  }
}
