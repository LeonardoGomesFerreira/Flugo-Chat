import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../app.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameCtrl    = TextEditingController();
  bool _loadingPhoto = false;
  bool _loadingName  = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = FirebaseAuth.instance.currentUser?.displayName ?? '';
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _pickPhoto() async {
    HapticFeedback.selectionClick();
    final picker = ImagePicker();
    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 600,
    );
    if (xfile == null) return;
    setState(() { _loadingPhoto = true; _error = null; _success = null; });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final ref  = FirebaseStorage.instance.ref('avatars/${user.uid}.jpg');
      await ref.putFile(File(xfile.path));
      final url = await ref.getDownloadURL();
      await user.updatePhotoURL(url);
      // Força o Firebase a notificar o authStateChanges com dados novos
      await FirebaseAuth.instance.currentUser!.reload();
      // Dispara o stream manualmente atualizando o token
      await FirebaseAuth.instance.currentUser!.getIdToken(true);
      if (mounted) setState(() => _success = 'Foto atualizada!');
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro ao enviar foto.');
    } finally {
      if (mounted) setState(() => _loadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FlugoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Remover foto',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: FlugoColors.textPrimary)),
        content: Text('Deseja remover sua foto de perfil?',
          style: GoogleFonts.inter(color: FlugoColors.textSecond)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.inter(color: FlugoColors.textSecond))),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: Text('Remover',
              style: GoogleFonts.inter(color: FlugoColors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() { _loadingPhoto = true; _error = null; _success = null; });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      // Remove do Storage
      try {
        await FirebaseStorage.instance.ref('avatars/${user.uid}.jpg').delete();
      } catch (_) {}
      await user.updatePhotoURL(null);
      await FirebaseAuth.instance.currentUser!.reload();
      await FirebaseAuth.instance.currentUser!.getIdToken(true);
      if (mounted) setState(() => _success = 'Foto removida!');
    } catch (_) {
      if (mounted) setState(() => _error = 'Erro ao remover foto.');
    } finally {
      if (mounted) setState(() => _loadingPhoto = false);
    }
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) { setState(() => _error = 'Nome não pode ser vazio'); return; }
    setState(() { _loadingName = true; _error = null; _success = null; });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.updateDisplayName(name);
      await FirebaseAuth.instance.currentUser!.reload();
      await FirebaseAuth.instance.currentUser!.getIdToken(true);
      if (mounted) setState(() => _success = 'Nome atualizado!');
    } catch (_) {
      if (mounted) setState(() => _error = 'Erro ao salvar nome');
    } finally {
      if (mounted) setState(() => _loadingName = false);
    }
  }

  static const _palette = [
    Color(0xFF22C55E), Color(0xFF60A5FA), Color(0xFFFB923C),
    Color(0xFFA78BFA), Color(0xFFF472B6), Color(0xFF34D399),
    Color(0xFFFBBF24), Color(0xFF38BDF8),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlugoColors.dark,
      appBar: AppBar(
        backgroundColor: FlugoColors.appBar,
        title: Text('Meu Perfil',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: FlugoColors.border)),
      ),
      // ── StreamBuilder: reconstrói em tempo real quando foto/nome mudam ──
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.userChanges(), // userChanges > authStateChanges para perfil
        builder: (context, snap) {
          final user = snap.data ?? FirebaseAuth.instance.currentUser;
          if (user == null) return const SizedBox();

          final name      = user.displayName ?? user.email?.split('@').first ?? 'Usuário';
          final email     = user.email ?? '';
          final photoUrl  = user.photoURL;
          final avatarColor = _palette[user.uid.hashCode.abs() % _palette.length];
          final initials  = name.trim().split(' ')
              .where((p) => p.isNotEmpty).take(2)
              .map((p) => p[0].toUpperCase()).join();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // ── Avatar atualizado em tempo real ──
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: avatarColor.withValues(alpha: 0.4), width: 2.5),
                      ),
                      child: ClipOval(
                        child: _loadingPhoto
                            ? Container(
                                color: avatarColor.withValues(alpha: 0.2),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: FlugoColors.primary)))
                            : photoUrl != null
                                ? Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    // Força recarregar a imagem quando a URL muda
                                    key: ValueKey(photoUrl),
                                    loadingBuilder: (_, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        color: avatarColor.withValues(alpha: 0.2),
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2)));
                                    },
                                    errorBuilder: (context, error, stack) =>
                                        _InitialsAvatar(initials: initials, color: avatarColor),
                                  )
                                : _InitialsAvatar(initials: initials, color: avatarColor),
                      ),
                    ),
                    // Botão câmera
                    GestureDetector(
                      onTap: _loadingPhoto ? null : _pickPhoto,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: FlugoColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: FlugoColors.dark, width: 2.5),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                          size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(name,
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700,
                    color: FlugoColors.textPrimary)),
                const SizedBox(height: 4),
                Text(email,
                  style: GoogleFonts.inter(fontSize: 13, color: FlugoColors.textSecond)),

                const SizedBox(height: 36),

                // ── Card nome ──
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: FlugoColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: FlugoColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Editar informações',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
                          color: FlugoColors.textPrimary)),
                      const SizedBox(height: 20),
                      Text('Nome de exibição',
                        style: GoogleFonts.inter(fontSize: 12, color: FlugoColors.textSecond,
                          fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: FlugoColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: FlugoColors.border),
                        ),
                        child: TextField(
                          controller: _nameCtrl,
                          style: const TextStyle(color: FlugoColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Seu nome',
                            hintStyle: TextStyle(color: FlugoColors.textHint),
                            prefixIcon: Icon(Icons.person_outline_rounded,
                              size: 19, color: FlugoColors.textSecond),
                            border:             InputBorder.none,
                            enabledBorder:      InputBorder.none,
                            focusedBorder:      InputBorder.none,
                            disabledBorder:     InputBorder.none,
                            errorBorder:        InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            filled: false,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadingName ? null : _saveName,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FlugoColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _loadingName
                            ? const SizedBox(height: 22, width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: Colors.white))
                            : const Text('SALVAR NOME'),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        _Banner(message: _error!, isError: true),
                      ],
                      if (_success != null) ...[
                        const SizedBox(height: 14),
                        _Banner(message: _success!, isError: false),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Card foto ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: FlugoColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: FlugoColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Foto de perfil',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
                          color: FlugoColors.textPrimary)),
                      const SizedBox(height: 6),
                      Text('Escolha uma foto da galeria ou remova a atual.',
                        style: GoogleFonts.inter(fontSize: 13, color: FlugoColors.textSecond,
                          height: 1.5)),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _loadingPhoto ? null : _pickPhoto,
                        icon: const Icon(Icons.photo_library_outlined, size: 19),
                        label: const Text('Escolher da galeria'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FlugoColors.primary,
                          side: const BorderSide(color: FlugoColors.primary, width: 1.5),
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      if (photoUrl != null) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _loadingPhoto ? null : _removePhoto,
                          icon: const Icon(Icons.delete_outline_rounded, size: 19),
                          label: const Text('Remover foto'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: FlugoColors.error,
                            side: BorderSide(
                              color: FlugoColors.error.withValues(alpha: 0.6), width: 1.5),
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  const _InitialsAvatar({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.18),
      alignment: Alignment.center,
      child: Text(initials,
        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

class _Banner extends StatelessWidget {
  final String message;
  final bool isError;
  const _Banner({required this.message, required this.isError});

  @override
  Widget build(BuildContext context) {
    final color = isError ? FlugoColors.error : FlugoColors.success;
    final icon  = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
          style: GoogleFonts.inter(color: color, fontSize: 13))),
      ]),
    );
  }
}