import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carrito  = context.watch<CarritoProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: const AppNavBar(),
      body: carrito.loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.charcoal))
          : carrito.items.isEmpty
              ? _EmptyCart()
              : isMobile
                  ? _MobileCart(carrito: carrito)
                  : _DesktopCart(carrito: carrito),
    );
  }
}

// ─── CARRITO VACÍO ─────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined,
            size: 64, color: AppColors.stone.withOpacity(0.3)),
          const SizedBox(height: 24),
          Text('Tu bolsa está vacía',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32, fontWeight: FontWeight.w300, color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text('Explorá la colección y encontrá algo que te guste.',
            style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone),
          ),
          const SizedBox(height: 40),
          PrimaryButton(
            label: 'Ir a la colección →',
            onPressed: () => context.go('/catalogo'),
          ),
        ],
      ),
    );
  }
}

// ─── DESKTOP ───────────────────────────────────────────────
class _DesktopCart extends StatelessWidget {
  final CarritoProvider carrito;
  const _DesktopCart({required this.carrito});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Lista items
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(64, 56, 64, 80),
            child: _CartItemsList(carrito: carrito),
          ),
        ),
        // Summary sidebar
        SizedBox(
          width: 380,
          child: Container(
            height: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.beige,
              border: Border(left: BorderSide(color: AppColors.sand)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: _OrderSummary(carrito: carrito),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── MOBILE ────────────────────────────────────────────────
class _MobileCart extends StatelessWidget {
  final CarritoProvider carrito;
  const _MobileCart({required this.carrito});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
            child: _CartItemsList(carrito: carrito),
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppColors.beige,
              border: Border(top: BorderSide(color: AppColors.sand)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 48),
            child: _OrderSummary(carrito: carrito),
          ),
        ],
      ),
    );
  }
}

// ─── LISTA DE ITEMS ────────────────────────────────────────
class _CartItemsList extends StatelessWidget {
  final CarritoProvider carrito;
  const _CartItemsList({required this.carrito});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('Mi Bolsa',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 40, fontWeight: FontWeight.w300, color: AppColors.ink,
              ),
            ),
            TextButton(
              onPressed: () => carrito.vaciar(),
              child: Text('Vaciar bolsa',
                style: GoogleFonts.dmMono(
                  fontSize: 10, color: AppColors.stone,
                  letterSpacing: 0.12,
                ),
              ),
            ),
          ],
        ),
        const Divider(color: AppColors.sand, height: 40, thickness: 1),
        ...carrito.items.map((item) => _CartItemRow(item: item)),
      ],
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final ItemCarrito item;
  const _CartItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final carrito = context.read<CarritoProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              SizedBox(
                width: 88, height: 110,
                child: _ItemThumbnail(url: item.imagenPrincipalUrl),
              ),
              const SizedBox(width: 24),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.titulo,
                      style: GoogleFonts.syne(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('TALLE ${item.talle.toUpperCase()}',
                      style: GoogleFonts.dmMono(
                        fontSize: 11, color: AppColors.stone,
                        letterSpacing: 0.08,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Qty control
                    _QtyControl(
                      cantidad: item.cantidad,
                      onDecrease: item.cantidad > 1
                          ? () => carrito.actualizarCantidad(
                                itemId: item.id,
                                cantidad: item.cantidad - 1,
                              )
                          : null,
                      onIncrease: () => carrito.actualizarCantidad(
                        itemId: item.id,
                        cantidad: item.cantidad + 1,
                      ),
                    ),
                  ],
                ),
              ),
              // Precio + eliminar
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(item.subtotalFormateado,
                    style: GoogleFonts.syne(
                      fontSize: 16, fontWeight: FontWeight.w400,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => carrito.eliminar(item.id),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text('Eliminar',
                      style: GoogleFonts.dmMono(
                        fontSize: 10, color: AppColors.stone,
                        letterSpacing: 0.12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: AppColors.sand, height: 1, thickness: 1),
        ],
      ),
    );
  }
}

class _QtyControl extends StatelessWidget {
  final int cantidad;
  final VoidCallback? onDecrease;
  final VoidCallback onIncrease;
  const _QtyControl({
    required this.cantidad,
    required this.onDecrease,
    required this.onIncrease,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.sand),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(icon: Icons.remove, onTap: onDecrease),
          SizedBox(
            width: 32,
            child: Center(
              child: Text('$cantidad',
                style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.charcoal),
              ),
            ),
          ),
          _QtyBtn(icon: Icons.add, onTap: onIncrease),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        color: Colors.transparent,
        child: Icon(icon, size: 14,
          color: onTap != null ? AppColors.charcoal : AppColors.stone),
      ),
    );
  }
}

// ─── ORDER SUMMARY ─────────────────────────────────────────
class _OrderSummary extends StatefulWidget {
  final CarritoProvider carrito;
  const _OrderSummary({required this.carrito});

  @override
  State<_OrderSummary> createState() => _OrderSummaryState();
}

class _OrderSummaryState extends State<_OrderSummary> {
  final _promoCtrl = TextEditingController();

  Future<void> _checkout() async {
    final direccionCtrl  = TextEditingController();
    final ciudadCtrl     = TextEditingController();
    final cpCtrl         = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: Text('Datos de envío',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24, fontWeight: FontWeight.w300, color: AppColors.ink,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthField(label: 'DIRECCIÓN', controller: direccionCtrl, hint: 'Av. Corrientes 1234'),
              const SizedBox(height: 16),
              AuthField(label: 'CIUDAD', controller: ciudadCtrl, hint: 'Buenos Aires'),
              const SizedBox(height: 16),
              AuthField(label: 'CÓDIGO POSTAL', controller: cpCtrl,
                hint: '1043', keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
              style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.cream,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              elevation: 0,
            ),
            child: Text('Confirmar',
              style: GoogleFonts.dmMono(fontSize: 11)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final dir = direccionCtrl.text.trim();
    final ciudad = ciudadCtrl.text.trim();
    final cp = cpCtrl.text.trim();

    if (dir.isEmpty || ciudad.isEmpty || cp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Completá todos los campos de envío',
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream)),
        backgroundColor: AppColors.charcoal,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final carrito = context.read<CarritoProvider>();
    final result = await carrito.confirmarCompra(
      direccionEnvio: dir,
      ciudad: ciudad,
      codigoPostal: cp,
    );

    if (!mounted) return;

    if (result != null) {
      final ordenId = result['ordenId'];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ Orden #$ordenId confirmada',
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.cream)),
        backgroundColor: AppColors.ink,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ));
      context.go('/');
    }
  }

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.carrito;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resumen',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 28, fontWeight: FontWeight.w300, color: AppColors.ink,
          ),
        ),
        const Divider(color: AppColors.sand, height: 36, thickness: 1),

        _SummaryRow(label: 'Subtotal', value: c.subtotalFormateado),
        _SummaryRow(label: 'Envío', value: 'Calculado al pagar'),
        _SummaryRow(label: 'Descuento', value: '—'),

        // Código promo
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoCtrl,
                  decoration: InputDecoration(
                    hintText: 'CÓDIGO PROMO',
                    hintStyle: GoogleFonts.dmMono(
                      fontSize: 10, color: AppColors.stone, letterSpacing: 0.12,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14,
                    ),
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
                      borderSide: BorderSide(color: AppColors.charcoal),
                    ),
                  ),
                  style: GoogleFonts.dmMono(fontSize: 11),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  color: AppColors.charcoal,
                  child: Text('APLICAR',
                    style: GoogleFonts.dmMono(
                      fontSize: 10, color: AppColors.cream, letterSpacing: 0.12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Total
        Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppColors.stone),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TOTAL',
                style: GoogleFonts.syne(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink,
                ),
              ),
              Text(c.subtotalFormateado,
                style: GoogleFonts.syne(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
        PrimaryButton(
          label: 'Finalizar compra',
          fullWidth: true,
          loading: widget.carrito.loading,
          onPressed: _checkout,
        ),
        const SizedBox(height: 12),
        Center(
          child: Text('PAGO SEGURO · ENVÍO A TODO EL PAÍS',
            style: GoogleFonts.dmMono(
              fontSize: 10, color: AppColors.stone, letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label.toUpperCase(),
            style: GoogleFonts.dmMono(
              fontSize: 11, color: AppColors.gray, letterSpacing: 0.08,
            ),
          ),
          Text(value,
            style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.charcoal),
          ),
        ],
      ),
    );
  }
}

class _ItemThumbnail extends StatelessWidget {
  final String? url;
  const _ItemThumbnail({this.url});

  @override
  Widget build(BuildContext context) {
    if (url != null && url!.isNotEmpty) {
      return Image.network(
        '${ApiService.serverUrl}$url',
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : Container(color: AppColors.beige),
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
        color: AppColors.beige,
        child: Center(
          child: Icon(Icons.shopping_bag_outlined,
              size: 32, color: AppColors.stone.withOpacity(0.3)),
        ),
      );
}
