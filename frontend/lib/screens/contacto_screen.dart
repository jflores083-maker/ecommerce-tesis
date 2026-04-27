import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/config_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ContactoScreen extends StatelessWidget {
  const ContactoScreen({super.key});

  Future<void> _abrirUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;

    final telefono = config.contactoTelefono;
    final email = config.contactoEmail;
    final direccion = config.contactoDireccion;
    final horario = config.contactoHorario;
    final numero = telefono.replaceAll(RegExp(r'[^\d]'), '');

    return Scaffold(
      appBar: const AppNavBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Container(
              width: double.infinity,
              color: AppColors.beige,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 80,
                vertical: 56,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Contacto',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: isMobile ? 48 : 72,
                      fontWeight: FontWeight.w300,
                      color: AppColors.ink,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Estamos para ayudarte.',
                    style: GoogleFonts.dmMono(
                        fontSize: 12, color: AppColors.stone),
                  ),
                ],
              ),
            ),

            // ── Datos ──
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 24 : 80,
                vertical: 48,
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._items(context, email, direccion, horario),
                        if (telefono.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          _WaBlock(
                            numero: numero,
                            telefono: telefono,
                            onTap: () => _abrirUrl('https://wa.me/$numero'),
                            fullWidth: true,
                          ),
                        ],
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                _items(context, email, direccion, horario),
                          ),
                        ),
                        const SizedBox(width: 80),
                        if (telefono.isNotEmpty)
                          _WaBlock(
                            numero: numero,
                            telefono: telefono,
                            onTap: () => _abrirUrl('https://wa.me/$numero'),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _items(
      BuildContext context, String email, String direccion, String horario) {
    return [
      if (direccion.isNotEmpty) ...[
        _ContactItem(
          icon: Icons.location_on_outlined,
          label: 'Dirección',
          value: direccion,
        ),
        const SizedBox(height: 32),
      ],
      if (horario.isNotEmpty) ...[
        _ContactItem(
          icon: Icons.schedule_outlined,
          label: 'Horario',
          value: horario,
        ),
        const SizedBox(height: 32),
      ],
      if (email.isNotEmpty)
        _ContactItem(
          icon: Icons.mail_outline,
          label: 'Email',
          value: email,
          onTap: () async {
            try {
              await launchUrl(Uri.parse('mailto:$email'),
                  webOnlyWindowName: '_blank');
            } catch (_) {}
          },
        ),
    ];
  }
}

class _ContactItem extends StatelessWidget {
  final dynamic icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final bool isFa;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.isFa = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.sand),
              color: AppColors.beige,
            ),
            child: Center(
              child: isFa
                  ? FaIcon(icon as FaIconData,
                      size: 18, color: AppColors.charcoal)
                  : Icon(icon as IconData, size: 20, color: AppColors.charcoal),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.dmMono(
                    fontSize: 10, color: AppColors.stone, letterSpacing: 0.15),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.syne(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                  decoration: onTap != null ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaBlock extends StatelessWidget {
  final String numero;
  final String telefono;
  final VoidCallback onTap;
  final bool fullWidth;
  const _WaBlock(
      {required this.numero,
      required this.telefono,
      required this.onTap,
      this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : 280,
      padding: const EdgeInsets.all(32),
      color: AppColors.ink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const FaIcon(FontAwesomeIcons.whatsapp,
              size: 32, color: AppColors.cream),
          const SizedBox(height: 20),
          Text(
            '¿Preferís hablar\ncon nosotros?',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: AppColors.cream,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Respondemos en minutos.',
            style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.cream,
              child: Text(
                'Escribinos →',
                style: GoogleFonts.dmMono(
                  fontSize: 12,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
