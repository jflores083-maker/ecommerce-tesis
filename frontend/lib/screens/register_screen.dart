import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool _passwordValida(String p) =>
      p.contains(RegExp(r'[A-Z]')) &&
      p.contains(RegExp(r'[a-z]')) &&
      p.contains(RegExp(r'[0-9]')) &&
      p.contains(RegExp(r'[^A-Za-z0-9]'));

  Future<void> _register() async {
    if (!_passwordValida(_passwordCtrl.text)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('La contraseña debe tener al menos una mayúscula, una minúscula, un número y un símbolo.'),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final email = await auth.register(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      telefono: '+54${_telefonoCtrl.text.trim()}',
      password: _passwordCtrl.text,
    );
    if (email != null && mounted) {
      context.go('/verificar-email', extra: email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const AppNavBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 0,
            vertical: 48,
          ),
          child: SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Crear cuenta',
                  style: GoogleFonts.syne(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Empezá a comprar en Urbal.',
                  style: GoogleFonts.dmMono(
                      fontSize: 12, color: AppColors.charcoal),
                ),
                const SizedBox(height: 40),
                if (auth.error != null) ...[
                  ErrorMsg(auth.error!),
                  const SizedBox(height: 16),
                ],
                AuthField(label: 'NOMBRE', controller: _nombreCtrl),
                const SizedBox(height: 12),
                AuthField(label: 'APELLIDO', controller: _apellidoCtrl),
                const SizedBox(height: 12),
                AuthField(
                    label: 'EMAIL',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                AuthField(
                  label: 'TELÉFONO',
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  hint: '3511234567',
                  prefix: Text(
                    '+54 ',
                    style: GoogleFonts.dmMono(
                        fontSize: 13, color: AppColors.charcoal),
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 12),
                AuthField(
                  label: 'CONTRASEÑA (mínimo 6 caracteres)',
                  controller: _passwordCtrl,
                  obscureText: !_showPass,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _showPass = !_showPass),
                    child: Icon(
                      _showPass
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.stone,
                    ),
                  ),
                  onSubmit: _register,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Crear cuenta',
                  fullWidth: true,
                  loading: auth.loading,
                  onPressed: _register,
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('¿Ya tenés cuenta? ',
                          style: GoogleFonts.dmMono(
                              fontSize: 11, color: AppColors.stone)),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Ingresá',
                          style: GoogleFonts.dmMono(
                            fontSize: 11,
                            color: AppColors.charcoal,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
