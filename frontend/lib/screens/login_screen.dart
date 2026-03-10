import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _showPass = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final ok = await auth.login(
      email: _emailCtrl.text.trim(),
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
                Text('Ingresar',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 48, fontWeight: FontWeight.w300, color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Accedé a tu cuenta 638.',
                  style: GoogleFonts.dmMono(fontSize: 12, color: AppColors.stone),
                ),
                const SizedBox(height: 40),
                if (auth.error != null) ...[
                  ErrorMsg(auth.error!),
                  const SizedBox(height: 16),
                ],
                AuthField(label: 'EMAIL', controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                AuthField(
                  label: 'CONTRASEÑA',
                  controller: _passwordCtrl,
                  obscureText: !_showPass,
                  suffix: GestureDetector(
                    onTap: () => setState(() => _showPass = !_showPass),
                    child: Icon(
                      _showPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18, color: AppColors.stone,
                    ),
                  ),
                  onSubmit: _login,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Ingresar', fullWidth: true,
                  loading: auth.loading, onPressed: _login,
                ),
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('¿No tenés cuenta? ',
                        style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.stone)),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: Text('Registrate',
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
