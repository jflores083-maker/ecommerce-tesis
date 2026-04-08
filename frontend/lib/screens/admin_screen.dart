import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: const AppNavBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 0,
          vertical: 48,
        ),
        child: Center(
          child: SizedBox(
            width: 560,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Panel Admin',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 40, fontWeight: FontWeight.w300, color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Gestión de productos 638.',
                  style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
                ),
                const SizedBox(height: 48),
                _AdminMenuBtn(
                  icon: Icons.bar_chart_outlined,
                  label: 'Dashboard',
                  description: 'Estadísticas y métricas de la tienda',
                  onTap: () => context.go('/admin/dashboard'),
                ),
                const SizedBox(height: 16),
                _AdminMenuBtn(
                  icon: Icons.add_box_outlined,
                  label: 'Agregar producto',
                  description: 'Publicar un nuevo producto en la tienda',
                  onTap: () => context.go('/admin/agregar'),
                ),
                const SizedBox(height: 16),
                _AdminMenuBtn(
                  icon: Icons.edit_outlined,
                  label: 'Modificar producto',
                  description: 'Editar precio, stock, talles y más',
                  onTap: () => context.go('/admin/modificar'),
                ),
                const SizedBox(height: 16),
                _AdminMenuBtn(
                  icon: Icons.delete_outline,
                  label: 'Eliminar producto',
                  description: 'Dar de baja un producto de la tienda',
                  onTap: () => context.go('/admin/eliminar'),
                ),
                const SizedBox(height: 16),
                _AdminMenuBtn(
                  icon: Icons.palette_outlined,
                  label: 'Personalización',
                  description: 'Imagen del inicio y tema de colores',
                  onTap: () => context.go('/admin/personalizacion'),
                ),
                const SizedBox(height: 16),
                _AdminMenuBtn(
                  icon: Icons.bolt_outlined,
                  label: 'Drops',
                  description: 'Gestionar lanzamientos exclusivos',
                  onTap: () => context.go('/admin/drops'),
                ),
                const SizedBox(height: 16),
                _AdminMenuBtn(
                  icon: Icons.local_offer_outlined,
                  label: 'Códigos de promoción',
                  description: 'Crear y gestionar descuentos para clientes',
                  onTap: () => context.go('/admin/codigos'),
                ),
                const SizedBox(height: 16),
                _AdminMenuBtn(
                  icon: Icons.trending_up_outlined,
                  label: 'Ajuste de precios',
                  description: 'Subir o bajar precios por porcentaje',
                  onTap: () => context.go('/admin/precios'),
                ),
                const SizedBox(height: 16),
                _AdminMenuBtn(
                  icon: Icons.receipt_long_outlined,
                  label: 'Órdenes',
                  description: 'Ver y gestionar todos los pedidos',
                  onTap: () => context.go('/admin/ordenes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminMenuBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _AdminMenuBtn({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.sand),
          color: AppColors.cream,
        ),
        child: Row(
          children: [
            Icon(icon, size: 28, color: AppColors.charcoal),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                    style: GoogleFonts.syne(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description,
                    style: GoogleFonts.dmMono(
                      fontSize: 11, color: AppColors.stone,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.stone),
          ],
        ),
      ),
    );
  }
}
