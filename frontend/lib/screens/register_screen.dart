import 'package:flutter/material.dart';
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
  final _nombreCtrl   = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
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

  Future<void> _register() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final ok = await auth.register(
      nombre:   _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      email:    _emailCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      password: _passwordCtrl.text,
    );
    if (ok && mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: const AppNavBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 0, vertical: 48,
          ),
          child: SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crear cuenta',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 48, fontWeight: FontWeight.w300, color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Empezá a comprar en 638.',
                  style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone),
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
                AuthField(label: 'EMAIL', controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 12),
                AuthField(
                  label: 'TELÉFONO (ej: +5435112345678)',
                  controller: _telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  hint: '+54...',
                ),
                const SizedBox(height: 12),
                AuthField(
                  label: 'CONTRASEÑA (mínimo 6 caracteres)',
                  controller: _passwordCtrl,
                  obscureText: !_showPass,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _showPass = !_showPass),
                    child: Icon(
                      _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18, color: AppColors.stone,
                    ),
                  ),
                  onSubmit: _register,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Crear cuenta', fullWidth: true,
                  loading: auth.loading, onPressed: _register,
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('¿Ya tenés cuenta? ',
                        style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone)),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text('Ingresá',
                          style: GoogleFonts.dmMono(
                            fontSize: 11, color: AppColors.charcoal,
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
