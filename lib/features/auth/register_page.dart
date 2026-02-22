import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_service.dart';
import 'login_page.dart';

enum _VS { empty, valid, invalid, warning }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _name        = TextEditingController();
  final _email       = TextEditingController();
  final _pass        = TextEditingController();
  final _passConfirm = TextEditingController();
  bool _loading  = false;
  bool _obscure  = true;
  bool _obscure2 = true;
  String? _error;

  _VS _nameState        = _VS.empty;
  _VS _emailState       = _VS.empty;
  _VS _passState        = _VS.empty;
  _VS _passConfirmState = _VS.empty;
  int _passStrength     = 0;

  late AnimationController _anim;
  late Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
    _name.addListener(_validateName);
    _email.addListener(_validateEmail);
    _pass.addListener(_validatePass);
    _passConfirm.addListener(_validateConfirm);
  }

  // Nome: mínimo 2 palavras, cada uma com ≥ 2 caracteres
  void _validateName() {
    final v = _name.text.trim();
    if (v.isEmpty) { setState(() => _nameState = _VS.empty); return; }
    final parts = v.split(' ').where((p) => p.length >= 2).toList();
    if (parts.length < 2) {
      setState(() => _nameState = v.contains(' ') ? _VS.warning : _VS.warning);
    } else {
      setState(() => _nameState = _VS.valid);
    }
  }

  // E-mail: RFC básico
  void _validateEmail() {
    final v = _email.text.trim();
    if (v.isEmpty) { setState(() => _emailState = _VS.empty); return; }
    setState(() => _emailState =
        RegExp(r'^[\w\.\-\+]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(v)
            ? _VS.valid : _VS.invalid);
  }

  // Senha: mínimo 6, avalia força
  void _validatePass() {
    final v = _pass.text;
    if (v.isEmpty) { setState(() { _passState = _VS.empty; _passStrength = 0; }); return; }
    if (v.length < 6) { setState(() { _passState = _VS.invalid; _passStrength = 0; }); return; }
    int score = 0;
    if (v.length >= 8) score++;
    if (v.contains(RegExp(r'[A-Z]'))) score++;
    if (v.contains(RegExp(r'[0-9]'))) score++;
    if (v.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    setState(() {
      _passStrength = score;
      _passState = score <= 1 ? _VS.invalid : score <= 2 ? _VS.warning : _VS.valid;
    });
    _validateConfirm(); // re-valida confirmação quando senha muda
  }

  // Confirmação: deve ser igual à senha
  void _validateConfirm() {
    final v = _passConfirm.text;
    if (v.isEmpty) { setState(() => _passConfirmState = _VS.empty); return; }
    setState(() => _passConfirmState =
        v == _pass.text ? _VS.valid : _VS.invalid);
  }

  @override
  void dispose() {
    _name.dispose(); _email.dispose();
    _pass.dispose(); _passConfirm.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Dispara todas as validações
    _validateName(); _validateEmail(); _validatePass(); _validateConfirm();

    // Checa cada campo com mensagem específica
    if (_nameState != _VS.valid) {
      setState(() => _error = 'Informe nome e sobrenome (ex: João Silva)');
      return;
    }
    if (_emailState != _VS.valid) {
      setState(() => _error = 'Informe um e-mail válido');
      return;
    }
    if (_passState == _VS.empty || _passState == _VS.invalid) {
      setState(() => _error = 'A senha deve ter no mínimo 6 caracteres');
      return;
    }
    if (_passConfirmState != _VS.valid) {
      setState(() => _error = 'As senhas não coincidem');
      return;
    }

    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().signUp(
        email: _email.text.trim(),
        password: _pass.text,
        displayName: _name.text.trim(),
      );
      // Faz signOut ANTES do dialog para garantir que AuthGate mostre LoginPage
      await AuthService().signOut();
      if (!mounted) return;
      // Sucesso: mostra feedback e vai para login
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF22C55E), size: 36),
            ),
            const SizedBox(height: 16),
            Text('Conta criada!',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800,
                color: Colors.white)),
            const SizedBox(height: 8),
            Text('Sua conta foi criada com sucesso.\nAgora faça o login para entrar.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8),
                height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('FAZER LOGIN',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      );
      if (!mounted) return;
      // Volta para login e limpa o stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _borderColor(_VS s) {
    switch (s) {
      case _VS.valid:   return const Color(0xFF22C55E).withValues(alpha: 0.8);
      case _VS.invalid: return const Color(0xFFEF4444).withValues(alpha: 0.8);
      case _VS.warning: return const Color(0xFFF59E0B).withValues(alpha: 0.8);
      case _VS.empty:   return Colors.white.withValues(alpha: 0.2);
    }
  }

  Widget? _suffix(_VS s, {bool isPassword = false, bool isConfirm = false}) {
    if (isPassword || isConfirm) return null; // tratado externamente
    switch (s) {
      case _VS.valid:
        return const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 18);
      case _VS.invalid:
        return const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 18);
      case _VS.warning:
        return const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18);
      case _VS.empty:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Criar conta',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // ── Logo ──
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.35), width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset('assets/flugo-tranparente.svg',
                      width: 44, height: 44, fit: BoxFit.contain,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF22C55E), BlendMode.srcIn)),
                  ),
                  const SizedBox(height: 16),
                  Text('Crie sua conta',
                    style: GoogleFonts.inter(fontSize: 24,
                      fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('Junte-se ao Flugo Chat',
                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF94A3B8))),
                  const SizedBox(height: 28),

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
                        // Nome completo
                        _Field(
                          controller: _name,
                          hint: 'Nome completo (ex: João Silva)',
                          icon: Icons.person_outline_rounded,
                          borderColor: _borderColor(_nameState),
                          borderWidth: _nameState == _VS.empty ? 1.5 : 1.8,
                          iconColor: _nameState == _VS.valid ? const Color(0xFF22C55E)
                              : _nameState == _VS.invalid ? const Color(0xFFEF4444)
                              : _nameState == _VS.warning ? const Color(0xFFF59E0B)
                              : const Color(0xFF94A3B8),
                          suffix: _suffix(_nameState),
                          errorText: _nameState == _VS.invalid ? 'Nome inválido' : null,
                          warnText: _nameState == _VS.warning
                              ? 'Informe nome e sobrenome' : null,
                        ),
                        const SizedBox(height: 14),

                        // E-mail
                        _Field(
                          controller: _email,
                          hint: 'E-mail',
                          icon: Icons.email_outlined,
                          borderColor: _borderColor(_emailState),
                          borderWidth: _emailState == _VS.empty ? 1.5 : 1.8,
                          keyboardType: TextInputType.emailAddress,
                          iconColor: _emailState == _VS.valid ? const Color(0xFF22C55E)
                              : _emailState == _VS.invalid ? const Color(0xFFEF4444)
                              : const Color(0xFF94A3B8),
                          suffix: _suffix(_emailState),
                          errorText: _emailState == _VS.invalid ? 'E-mail inválido' : null,
                        ),
                        const SizedBox(height: 14),

                        // Senha
                        _Field(
                          controller: _pass,
                          hint: 'Senha (mín. 6 caracteres)',
                          icon: Icons.lock_outline_rounded,
                          borderColor: _borderColor(_passState),
                          borderWidth: _passState == _VS.empty ? 1.5 : 1.8,
                          obscure: _obscure,
                          iconColor: _passState == _VS.valid ? const Color(0xFF22C55E)
                              : _passState == _VS.invalid ? const Color(0xFFEF4444)
                              : _passState == _VS.warning ? const Color(0xFFF59E0B)
                              : const Color(0xFF94A3B8),
                          suffix: IconButton(
                            icon: Icon(_obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                              size: 19, color: const Color(0xFF94A3B8)),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          errorText: _passState == _VS.invalid && _pass.text.isNotEmpty
                              ? 'Mínimo 6 caracteres' : null,
                        ),

                        // Barra de força
                        if (_pass.text.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _StrengthBar(strength: _passStrength),
                        ],
                        const SizedBox(height: 14),

                        // Confirmar senha
                        _Field(
                          controller: _passConfirm,
                          hint: 'Confirmar senha',
                          icon: Icons.lock_outline_rounded,
                          borderColor: _borderColor(_passConfirmState),
                          borderWidth: _passConfirmState == _VS.empty ? 1.5 : 1.8,
                          obscure: _obscure2,
                          iconColor: _passConfirmState == _VS.valid ? const Color(0xFF22C55E)
                              : _passConfirmState == _VS.invalid ? const Color(0xFFEF4444)
                              : const Color(0xFF94A3B8),
                          suffix: IconButton(
                            icon: Icon(_obscure2
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                              size: 19, color: const Color(0xFF94A3B8)),
                            onPressed: () => setState(() => _obscure2 = !_obscure2),
                          ),
                          errorText: _passConfirmState == _VS.invalid
                              ? 'As senhas não coincidem' : null,
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          onPressed: _loading ? null : _register,
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
                              : const Text('CADASTRAR'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(fontSize: 14,
                          color: const Color(0xFF94A3B8)),
                        children: const [
                          TextSpan(text: 'Já tem conta? '),
                          TextSpan(text: 'Entrar',
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
  final TextInputType? keyboardType;
  final String? errorText;
  final String? warnText;

  const _Field({
    required this.controller, required this.hint, required this.icon,
    required this.borderColor, required this.borderWidth, required this.iconColor,
    this.obscure = false, this.suffix, this.keyboardType,
    this.errorText, this.warnText,
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
        if (warnText != null) ...[
          const SizedBox(height: 4),
          Padding(padding: const EdgeInsets.only(left: 4),
            child: Text(warnText!, style: GoogleFonts.inter(
              fontSize: 11.5, color: const Color(0xFFF59E0B)))),
        ],
      ],
    );
  }
}

// ── Barra de força da senha ───────────────────────────────────────────────
class _StrengthBar extends StatelessWidget {
  final int strength;
  const _StrengthBar({required this.strength});

  @override
  Widget build(BuildContext context) {
    final labels = ['Muito fraca', 'Fraca', 'Razoável', 'Boa', 'Forte'];
    final colors = [
      const Color(0xFFEF4444), const Color(0xFFEF4444),
      const Color(0xFFF59E0B), const Color(0xFFF59E0B), const Color(0xFF22C55E),
    ];
    final color = colors[strength.clamp(0, 4)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: List.generate(4, (i) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: i < strength ? color : Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ))),
        const SizedBox(height: 4),
        Text(labels[strength.clamp(0, 4)],
          style: GoogleFonts.inter(fontSize: 11.5, color: color,
            fontWeight: FontWeight.w500)),
      ],
    );
  }
}