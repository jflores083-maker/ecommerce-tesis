import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/carrito_provider.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final carrito = context.watch<CarritoProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: const AppNavBar(),
      body: carrito.loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.charcoal))
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
          Text(
            'Tu bolsa está vacía',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Explorá la colección y encontrá algo que te guste.',
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
            Text(
              'Mi Bolsa',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 40,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            TextButton(
              onPressed: () => carrito.vaciar(),
              child: Text(
                'Vaciar bolsa',
                style: GoogleFonts.dmMono(
                  fontSize: 10,
                  color: AppColors.stone,
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
                width: 88,
                height: 110,
                child: _ItemThumbnail(url: item.imagenPrincipalUrl),
              ),
              const SizedBox(width: 24),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.titulo,
                      style: GoogleFonts.syne(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TALLE ${item.talle.toUpperCase()}',
                      style: GoogleFonts.dmMono(
                        fontSize: 11,
                        color: AppColors.stone,
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
                  Text(
                    item.subtotalFormateado,
                    style: GoogleFonts.syne(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
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
                    child: Text(
                      'Eliminar',
                      style: GoogleFonts.dmMono(
                        fontSize: 10,
                        color: AppColors.stone,
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
              child: Text(
                '$cantidad',
                style:
                    GoogleFonts.dmMono(fontSize: 12, color: AppColors.charcoal),
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
        width: 32,
        height: 32,
        color: Colors.transparent,
        child: Icon(icon,
            size: 14,
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
    final direccionCtrl = TextEditingController();
    final ciudadCtrl = TextEditingController();
    final cpCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cream,
        title: Text(
          'Datos de envío',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AuthField(
                  label: 'DIRECCIÓN',
                  controller: direccionCtrl,
                  hint: 'Av. Corrientes 1234'),
              const SizedBox(height: 16),
              AuthField(
                  label: 'CIUDAD',
                  controller: ciudadCtrl,
                  hint: 'Buenos Aires'),
              const SizedBox(height: 16),
              AuthField(
                  label: 'CÓDIGO POSTAL',
                  controller: cpCtrl,
                  hint: '1043',
                  keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style:
                    GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ink,
              foregroundColor: AppColors.cream,
              shape:
                  const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              elevation: 0,
            ),
            child: Text('Confirmar', style: GoogleFonts.dmMono(fontSize: 11)),
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

    if (!mounted) return;
    final carrito = context.read<CarritoProvider>();

    // Paso 2: selección de medio de pago
    final metodo = await showDialog<String>(
      context: context,
      builder: (_) => _MetodoPagoDialog(subtotal: carrito.subtotal),
    );
    if (metodo == null || !mounted) return;

    // Paso 3: procesamiento
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PagoDialog(
        carrito: carrito,
        direccionEnvio: dir,
        ciudad: ciudad,
        codigoPostal: cp,
        metodo: metodo,
        onDone: () => context.go('/'),
      ),
    );
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
        Text(
          'Resumen',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const Divider(color: AppColors.sand, height: 36, thickness: 1),

        _SummaryRow(label: 'Subtotal', value: c.subtotalFormateado),
        const _SummaryRow(label: 'Envío', value: 'Calculado al pagar'),
        const _SummaryRow(label: 'Descuento', value: '—'),

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
                      fontSize: 10,
                      color: AppColors.stone,
                      letterSpacing: 0.12,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  color: AppColors.charcoal,
                  child: Text(
                    'APLICAR',
                    style: GoogleFonts.dmMono(
                      fontSize: 10,
                      color: AppColors.cream,
                      letterSpacing: 0.12,
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
              Text(
                'TOTAL',
                style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              Text(
                c.subtotalFormateado,
                style: GoogleFonts.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
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
          child: Text(
            'PAGO SEGURO · ENVÍO A TODO EL PAÍS',
            style: GoogleFonts.dmMono(
              fontSize: 10,
              color: AppColors.stone,
              letterSpacing: 0.1,
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
          Text(
            label.toUpperCase(),
            style: GoogleFonts.dmMono(
              fontSize: 11,
              color: AppColors.gray,
              letterSpacing: 0.08,
            ),
          ),
          Text(
            value,
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

// ─── SELECCIÓN MEDIO DE PAGO ───────────────────────────────
class _MetodoPagoDialog extends StatefulWidget {
  final double subtotal;
  const _MetodoPagoDialog({required this.subtotal});

  @override
  State<_MetodoPagoDialog> createState() => _MetodoPagoDialogState();
}

class _MetodoPagoDialogState extends State<_MetodoPagoDialog> {
  String? _seleccionado;

  static const _metodos = [
    _Metodo('tarjeta', 'Tarjeta de crédito o débito',
        Icons.credit_card_outlined, 'HASTA 6 CUOTAS SIN INTERÉS'),
    _Metodo(
        'transferencia', 'Transferencia', Icons.account_balance_outlined, null),
    _Metodo('efectivo', 'Efectivo', Icons.payments_outlined, null),
    _Metodo('mercadopago', 'Mercado Pago', Icons.open_in_new_outlined,
        'HASTA 6 CUOTAS SIN INTERÉS'),
    _Metodo('cuotas_mp', 'Cuotas sin Tarjeta de Mercado Pago',
        Icons.open_in_new_outlined, null),
  ];

  String _badgeTransferencia() {
    final precio = (widget.subtotal * 0.9).toStringAsFixed(0);
    final parts = <String>[];
    int n = int.tryParse(precio) ?? 0;
    String s = n.toString();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) parts.add('.');
      parts.add(s[i]);
    }
    return 'PAGÁS \$${parts.join()}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medio de pago',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 20),
              ..._metodos.map((m) {
                final badge =
                    m.id == 'transferencia' ? _badgeTransferencia() : m.badge;
                final isMp = m.id == 'mercadopago';
                return _MetodoRow(
                  metodo: m,
                  badge: badge,
                  isMercadoPago: isMp,
                  seleccionado: _seleccionado == m.id,
                  onTap: () => setState(() => _seleccionado = m.id),
                );
              }),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _seleccionado == null
                      ? null
                      : () => Navigator.of(context).pop(_seleccionado),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    disabledBackgroundColor: AppColors.sand,
                    foregroundColor: AppColors.cream,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                  ),
                  child: Text(
                    'REALIZAR PEDIDO',
                    style:
                        GoogleFonts.dmMono(fontSize: 11, letterSpacing: 0.15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metodo {
  final String id;
  final String label;
  final IconData icon;
  final String? badge;
  const _Metodo(this.id, this.label, this.icon, this.badge);
}

class _MetodoRow extends StatelessWidget {
  final _Metodo metodo;
  final String? badge;
  final bool isMercadoPago;
  final bool seleccionado;
  final VoidCallback onTap;
  const _MetodoRow({
    required this.metodo,
    required this.badge,
    required this.isMercadoPago,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cream,
          border: Border.all(
            color: seleccionado ? AppColors.ink : AppColors.sand,
            width: seleccionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.sand),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(metodo.icon, size: 18, color: AppColors.charcoal),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isMercadoPago)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE600),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'mercado pago',
                        style: GoogleFonts.dmMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF009EE3),
                        ),
                      ),
                    )
                  else
                    Text(
                      metodo.label,
                      style: GoogleFonts.syne(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  if (badge != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.charcoal,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge!,
                        style: GoogleFonts.dmMono(
                          fontSize: 9,
                          color: AppColors.cream,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.stone),
          ],
        ),
      ),
    );
  }
}

// ─── MODAL PROCESANDO PAGO ─────────────────────────────────
class _PagoDialog extends StatefulWidget {
  final CarritoProvider carrito;
  final String direccionEnvio;
  final String ciudad;
  final String codigoPostal;
  final String metodo;
  final VoidCallback onDone;

  const _PagoDialog({
    required this.carrito,
    required this.direccionEnvio,
    required this.ciudad,
    required this.codigoPostal,
    required this.metodo,
    required this.onDone,
  });

  @override
  State<_PagoDialog> createState() => _PagoDialogState();
}

class _PagoDialogState extends State<_PagoDialog>
    with SingleTickerProviderStateMixin {
  bool _exitoso = false;
  String? _error;
  int? _ordenId;
  late AnimationController _tickCtrl;
  late Animation<double> _tickAnim;

  @override
  void initState() {
    super.initState();
    _tickCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _tickAnim = CurvedAnimation(parent: _tickCtrl, curve: Curves.easeOutBack);
    _procesarPago();
  }

  Future<void> _procesarPago() async {
    // Paso 1: crear la orden
    final result = await widget.carrito.confirmarCompra(
      direccionEnvio: widget.direccionEnvio,
      ciudad: widget.ciudad,
      codigoPostal: widget.codigoPostal,
    );
    if (!mounted) return;
    if (result == null) {
      setState(() => _error = widget.carrito.error ?? 'Ocurrió un error');
      return;
    }

    final ordenId = result['ordenId'] as int;
    setState(() => _ordenId = ordenId);

    // Paso 2: si eligió MercadoPago, iniciamos el pago y abrimos WebView
    if (widget.metodo == 'mercadopago' || widget.metodo == 'cuotas_mp') {
      try {
        final api = context.read<ApiService>();
        final pagoData = await api.iniciarPago(ordenId);
        final initPoint = pagoData['initPoint'] as String;

        if (!mounted) return;
        Navigator.of(context).pop(); // cerrar este dialog

        if (kIsWeb) {
          // En web, abrir en nueva pestaña
          await launchUrl(
            Uri.parse(initPoint),
            webOnlyWindowName: '_blank',
          );
          widget.onDone();
        } else {
          // En móvil, abrir WebView interno
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _MercadoPagoWebView(
                initPoint: initPoint,
                ordenId: ordenId,
              ),
            ),
          );
          widget.onDone();
        }
      } catch (e) {
        setState(() => _error = 'Error al iniciar el pago con MercadoPago');
      }
      return;
    }

    // Paso 3: otros métodos → mostrar confirmación directa
    setState(() => _exitoso = true);
    _tickCtrl.forward();
  }

  @override
  void dispose() {
    _tickCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: SizedBox(
          width: 320,
          child: _error != null
              ? _buildError()
              : _exitoso
                  ? _buildExito()
                  : _buildProcesando(),
        ),
      ),
    );
  }

  Widget _buildProcesando() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Procesando pago...',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'No cierres esta ventana.',
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
        ),
      ],
    );
  }

  Widget _buildExito() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _tickAnim,
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: AppColors.cream, size: 36),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          '¡Orden confirmada!',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Orden #$_ordenId generada con éxito.',
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'Continuar',
          fullWidth: true,
          onPressed: () {
            Navigator.of(context).pop();
            widget.onDone();
          },
        ),
      ],
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.red[50],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error_outline, color: Colors.red[700], size: 36),
        ),
        const SizedBox(height: 28),
        Text(
          'No se pudo procesar',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _error!,
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        OutlineBtn(
          label: 'Cerrar',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

// ─── WEBVIEW MERCADOPAGO ─────────────────────────────────────────────
class _MercadoPagoWebView extends StatefulWidget {
  final String initPoint;
  final int ordenId;
  const _MercadoPagoWebView({required this.initPoint, required this.ordenId});

  @override
  State<_MercadoPagoWebView> createState() => _MercadoPagoWebViewState();
}

class _MercadoPagoWebViewState extends State<_MercadoPagoWebView> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
        onNavigationRequest: (request) {
          // Detectar cuando MP redirige de vuelta (success/failure/pending)
          final url = request.url;
          if (url.contains('congrats') || url.contains('back_urls')) {
            Navigator.of(context).pop();
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      ..loadRequest(Uri.parse(widget.initPoint));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.ink,
        elevation: 0,
        title: Text(
          'Pago seguro',
          style: GoogleFonts.dmMono(fontSize: 13, color: AppColors.ink),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.ink),
            ),
        ],
      ),
    );
  }
}
