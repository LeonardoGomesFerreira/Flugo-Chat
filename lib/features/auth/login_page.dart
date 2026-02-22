import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_service.dart';
import 'register_page.dart';
import '../chat/chat_page.dart';

enum _FS { empty, invalid, valid }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  _FS _emailState = _FS.empty;
  _FS _passState  = _FS.empty;

  late AnimationController _anim;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
    _email.addListener(_validateEmail);
    _pass.addListener(_validatePass);
  }

  void _validateEmail() {
    final v = _email.text.trim();
    if (v.isEmpty) { setState(() => _emailState = _FS.empty); return; }
    setState(() => _emailState =
        RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(v)
            ? _FS.valid : _FS.invalid);
  }

  void _validatePass() {
    final v = _pass.text;
    if (v.isEmpty) { setState(() => _passState = _FS.empty); return; }
    setState(() => _passState = v.length >= 6 ? _FS.valid : _FS.invalid);
  }

  @override
  void dispose() {
    _email.dispose(); _pass.dispose(); _anim.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    _validateEmail(); _validatePass();

    if (_emailState != _FS.valid) {
      setState(() => _error = 'Informe um e-mail válido');
      return;
    }
    if (_passState != _FS.valid) {
      setState(() => _error = 'A senha deve ter no mínimo 6 caracteres');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().signIn(
        email: _email.text.trim(),
        password: _pass.text,
      );
      // Navega direto — não depende do stream do AuthGate
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ChatPage()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _borderColor(_FS s) {
    switch (s) {
      case _FS.valid:   return const Color(0xFF22C55E);
      case _FS.invalid: return const Color(0xFFEF4444);
      case _FS.empty:   return Colors.white.withValues(alpha: 0.2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Logo ──
                  Container(
                    width: 96, height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.35), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset('assets/flugo-tranparente.svg',
                      width: 48, height: 48, fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF22C55E), BlendMode.srcIn)),
                  ),
                  const SizedBox(height: 20),
                  Text('Flugo Chat',
                    style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text('Bem-vindo de volta!',
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8))),
                  const SizedBox(height: 36),

                  // ── Card ──
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Field(
                          controller: _email,
                          hint: 'E-mail',
                          icon: Icons.email_outlined,
                          borderColor: _borderColor(_emailState),
                          borderWidth: _emailState == _FS.empty ? 1.5 : 1.8,
                          keyboardType: TextInputType.emailAddress,
                          iconColor: _emailState == _FS.valid ? const Color(0xFF22C55E)
                              : _emailState == _FS.invalid ? const Color(0xFFEF4444)
                              : const Color(0xFF94A3B8),
                          suffix: _emailState == _FS.valid
                              ? const Icon(Icons.check_circle_rounded,
                                  color: Color(0xFF22C55E), size: 18)
                              : _emailState == _FS.invalid
                                  ? const Icon(Icons.cancel_rounded,
                                      color: Color(0xFFEF4444), size: 18)
                                  : null,
                          errorText: _emailState == _FS.invalid ? 'E-mail inválido' : null,
                        ),
                        const SizedBox(height: 14),
                        _Field(
                          controller: _pass,
                          hint: 'Senha',
                          icon: Icons.lock_outline_rounded,
                          borderColor: _borderColor(_passState),
                          borderWidth: _passState == _FS.empty ? 1.5 : 1.8,
                          obscure: _obscure,
                          onSubmit: (_) => _login(),
                          iconColor: _passState == _FS.valid ? const Color(0xFF22C55E)
                              : _passState == _FS.invalid ? const Color(0xFFEF4444)
                              : const Color(0xFF94A3B8),
                          suffix: IconButton(
                            icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                              size: 19, color: const Color(0xFF94A3B8)),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          errorText: _passState == _FS.invalid ? 'Mínimo 6 caracteres' : null,
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline_rounded,
                                color: Color(0xFFEF4444), size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_error!,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFEF4444), fontSize: 13))),
                            ]),
                          ),
                        ],

                        const SizedBox(height: 22),
                        ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                            textStyle: GoogleFonts.inter(
                              fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          child: _loading
                              ? const SizedBox(height: 22, width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                              : const Text('ENTRAR'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterPage())),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(fontSize: 14,
                          color: const Color(0xFF94A3B8)),
                        children: const [
                          TextSpan(text: 'Não tem conta? '),
                          TextSpan(text: 'Cadastre-se',
                            style: TextStyle(color: Color(0xFF22C55E),
                              fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Campo reutilizável ────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color borderColor;
  final double borderWidth;
  final Color iconColor;
  final bool obscure;
  final Widget? suffix;
  final Function(String)? onSubmit;
  final TextInputType? keyboardType;
  final String? errorText;

  const _Field({
    required this.controller, required this.hint, required this.icon,
    required this.borderColor, required this.borderWidth, required this.iconColor,
    this.obscure = false, this.suffix, this.onSubmit,
    this.keyboardType, this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF334155),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            onSubmitted: onSubmit,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF64748B)),
              border: InputBorder.none, enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none, disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none, focusedErrorBorder: InputBorder.none,
              filled: false,
              prefixIcon: Icon(icon, size: 19, color: iconColor),
              suffixIcon: suffix,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Padding(padding: const EdgeInsets.only(left: 4),
            child: Text(errorText!, style: GoogleFonts.inter(
              fontSize: 11.5, color: const Color(0xFFEF4444)))),
        ],
      ],
    );
  }
}
