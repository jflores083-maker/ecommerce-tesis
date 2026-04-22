import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class VerificarEmailScreen extends StatefulWidget {
  final String email;
  const VerificarEmailScreen({super.key, required this.email});

  @override
  State<VerificarEmailScreen> createState() => _VerificarEmailScreenState();
}

class _VerificarEmailScreenState extends State<VerificarEmailScreen> {
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());

  bool _reenviando = false;
  String? _reenviadoMsg;

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    super.dispose();
  }

  String get _codigo => _ctrls.map((c) => c.text).join();

  Future<void> _verificar() async {
    if (_codigo.length < 6) return;
    final auth = context.read<AuthProvider>();
    auth.clearError();
    final ok = await auth.verificarEmail(
      email: widget.email,
      codigo: _codigo,
    );
    if (ok && mounted) context.go('/');
  }

  Future<void> _reenviar() async {
    setState(() { _reenviando = true; _reenviadoMsg = null; });
    try {
      final api = context.read<ApiService>();
      await api.reenviarCodigo(email: widget.email);
      if (mounted) {
        setState(() {
          _reenviando = false;
          _reenviadoMsg = 'Código reenviado a ${widget.email}';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _nodes[index + 1].requestFocus();
    }
    // Si pegaron 6 dígitos en el primer campo
    if (value.length == 6) {
      for (int i = 0; i < 6; i++) {
        _ctrls[i].text = value[i];
      }
      _nodes[5].requestFocus();
      setState(() {});
      _verificar();
      return;
    }
    setState(() {});
    if (_codigo.length == 6) _verificar();
  }

  void _onKeyDown(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _ctrls[index].text.isEmpty &&
        index > 0) {
      _nodes[index - 1].requestFocus();
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
            horizontal: isMobile ? 24 : 0,
            vertical: 48,
          ),
          child: SizedBox(
            width: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verificá tu email',
                  style: GoogleFonts.syne(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ingresá el código de 6 dígitos que enviamos a:',
                  style: GoogleFonts.dmMono(
                      fontSize: 12, color: AppColors.charcoal),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.email,
                  style: GoogleFonts.dmMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink),
                ),
                const SizedBox(height: 40),

                if (auth.error != null) ...[
                  ErrorMsg(auth.error!),
                  const SizedBox(height: 16),
                ],

                if (_reenviadoMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.sand),
                      color: AppColors.beige,
                    ),
                    child: Text(_reenviadoMsg!,
                        style: GoogleFonts.dmMono(
                            fontSize: 11, color: AppColors.charcoal)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Inputs OTP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (i) => _OtpBox(
                    controller: _ctrls[i],
                    focusNode: _nodes[i],
                    onChanged: (v) => _onDigitChanged(i, v),
                    onKey: (e) => _onKeyDown(i, e),
                    autofocus: i == 0,
                  )),
                ),
                const SizedBox(height: 32),

                PrimaryButton(
                  label: 'Verificar',
                  fullWidth: true,
                  loading: auth.loading,
                  onPressed: _codigo.length == 6 ? _verificar : null,
                ),
                const SizedBox(height: 24),

                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¿No recibiste el código? ',
                        style: GoogleFonts.dmMono(
                            fontSize: 11, color: AppColors.stone),
                      ),
                      GestureDetector(
                        onTap: _reenviando ? null : _reenviar,
                        child: _reenviando
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: AppColors.charcoal),
                              )
                            : Text(
                                'Reenviar',
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

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<RawKeyEvent> onKey;
  final bool autofocus;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKey,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 64,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: onKey,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: autofocus,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6), // permite pegar 6 dígitos
          ],
          style: GoogleFonts.syne(
              fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.ink),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.sand),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.sand),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.ink, width: 1.5),
            ),
            filled: true,
            fillColor: controller.text.isNotEmpty
                ? AppColors.beige
                : AppColors.cream,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
