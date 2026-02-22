import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app.dart';
import '../auth/auth_service.dart';
import '../auth/profile_page.dart';
import 'chat_service.dart';
import 'message_bubble.dart';
import 'message_model.dart';
import 'notification_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final _service    = ChatService();
  final _controller = TextEditingController();
  final _scroll     = ScrollController();
  final _focusNode  = FocusNode();
  final _notif      = NotificationService();

  bool _sending = false;
  String? _error;
  ChatMessage? _replyTo;
  bool _hasText = false;
  bool _appInForeground = true;
  String? _lastKnownMessageId;
  bool _showScrollBtn = false;   // ← botão "ir à última mensagem"
  bool _initialScrollDone = false; // ← primeira carga rola até o fim

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notif.init();
    // Sincroniza perfil no Firebase para outros verem foto em tempo real
    ChatService().syncUserProfile(); // void - não precisa de await
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
    _scroll.addListener(() {
      final nearBottom = _scroll.hasClients &&
          _scroll.position.maxScrollExtent - _scroll.offset > 200;
      if (nearBottom != _showScrollBtn) setState(() => _showScrollBtn = nearBottom);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose(); _scroll.dispose(); _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scroll.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() { _sending = true; _error = null; });
    try {
      await _service.sendMessage(text, replyTo: _replyTo);
      _controller.clear();
      setState(() => _replyTo = null);
      _scrollToBottom();
    } catch (e) {
      setState(() => _error = 'Erro ao enviar: ${e.toString().replaceAll("Exception: ", "")}');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _onReply(ChatMessage msg) {
    setState(() => _replyTo = msg);
    _focusNode.requestFocus();
  }

  void _checkNewMessages(List<ChatMessage> messages, String currentUid) {
    if (messages.isEmpty) return;
    final last = messages.last;
    if (_lastKnownMessageId == null) { _lastKnownMessageId = last.id; return; }
    if (last.id != _lastKnownMessageId && last.userId != currentUid && !last.deleted) {
      _lastKnownMessageId = last.id;
      if (_appInForeground && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 80),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: FlugoColors.surface,
          elevation: 8,
          content: Row(children: [
            Container(width: 38, height: 38,
              decoration: BoxDecoration(
                color: FlugoColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle,
                border: Border.all(color: FlugoColors.primary.withValues(alpha: 0.3))),
              child: const Icon(Icons.chat_bubble_rounded, color: FlugoColors.primary, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, children: [
                Text(last.userName,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13,
                    color: FlugoColors.primary)),
                Text(last.text, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 13, color: FlugoColors.textPrimary)),
              ])),
          ]),
        ));
      } else {
        _notif.showMessage(title: last.userName, body: last.text, inForeground: false);
      }
    } else {
      _lastKnownMessageId = last.id;
    }
  }

  Future<void> _confirmSignOut() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FlugoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Sair', style: GoogleFonts.inter(fontWeight: FontWeight.w700,
          color: FlugoColors.textPrimary)),
        content: Text('Deseja encerrar sua sessão?',
          style: GoogleFonts.inter(color: FlugoColors.textSecond)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.inter(color: FlugoColors.textSecond))),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: Text('Sair', style: GoogleFonts.inter(
              color: FlugoColors.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok == true) AuthService().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final User? user = auth.currentUser;
    final currentUid = user?.uid ?? '';
    final userName   = user?.displayName ?? user?.email?.split('@').first ?? 'Usuário';
    final palette = [
      const Color(0xFF22C55E), const Color(0xFF60A5FA), const Color(0xFFFB923C),
      const Color(0xFFA78BFA), const Color(0xFFF472B6), const Color(0xFF34D399),
      const Color(0xFFFBBF24), const Color(0xFF38BDF8),
    ];
    final avatarColor = palette[currentUid.hashCode.abs() % palette.length];
    return Scaffold(
      backgroundColor: FlugoColors.chatBg,
      appBar: AppBar(
        backgroundColor: FlugoColors.appBar,
        elevation: 0,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.all(12),
          child: SvgPicture.asset('assets/flugo-tranparente.svg',
            colorFilter: const ColorFilter.mode(FlugoColors.primary, BlendMode.srcIn)),
        ),
        // ← Título clicável → perfil
        title: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfilePage())),
          child: Row(
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Flugo Chat',
                  style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700,
                    color: FlugoColors.textPrimary)),
                Row(children: [
                  Container(width: 7, height: 7,
                    decoration: const BoxDecoration(
                      color: FlugoColors.primary, shape: BoxShape.circle)),
                  const SizedBox(width: 5),
                  Text('online como $userName',
                    style: GoogleFonts.inter(fontSize: 11, color: FlugoColors.textSecond)),
                ]),
              ]),
            ],
          ),
        ),
        actions: [
          // Avatar com foto em tempo real via userChanges()
          StreamBuilder(
            stream: FirebaseAuth.instance.userChanges(),
            builder: (context, snap) {
              final liveUser = snap.data ?? user;
              final livePhoto = liveUser?.photoURL;
              final liveInitials = (liveUser?.displayName ?? userName)
                  .trim().split(' ')
                  .where((p) => p.isNotEmpty).take(2)
                  .map((p) => p[0].toUpperCase()).join();
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfilePage())),
                child: Container(
                  margin: const EdgeInsets.only(right: 6),
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: avatarColor.withValues(alpha: 0.5), width: 2)),
                  child: ClipOval(
                    child: livePhoto != null && livePhoto.isNotEmpty
                        ? Image.network(livePhoto, fit: BoxFit.cover,
                            key: ValueKey(livePhoto))
                        : Container(color: avatarColor.withValues(alpha: 0.2),
                            alignment: Alignment.center,
                            child: Text(liveInitials,
                              style: TextStyle(fontSize: 12,
                                fontWeight: FontWeight.w800, color: avatarColor))),
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout_rounded, color: FlugoColors.textSecond, size: 21),
            onPressed: _confirmSignOut,
          ),
          const SizedBox(width: 2),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: FlugoColors.border)),
      ),
      body: Column(
        children: [
          // ── Messages ──
          Expanded(
            child: Stack(
              children: [
                StreamBuilder<DatabaseEvent>(
                  stream: _service.messagesQuery(limit: 200).onValue,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator(
                        color: FlugoColors.primary, strokeWidth: 2.5));
                    }
                    final messages = _service.parseSnapshot(snap.data!.snapshot);
                    _checkNewMessages(messages, currentUid);
                    // Na primeira carga sempre rola; depois só se perto do fim
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_scroll.hasClients) return;
                      if (!_initialScrollDone) {
                        _initialScrollDone = true;
                        _scrollToBottom();
                        return;
                      }
                      final atBottom = _scroll.position.maxScrollExtent - _scroll.offset < 200;
                      if (atBottom) _scrollToBottom();
                    });

                    if (messages.isEmpty) {
                      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                          size: 56, color: FlugoColors.textSecond.withValues(alpha: 0.25)),
                        const SizedBox(height: 12),
                        Text('Nenhuma mensagem ainda',
                          style: GoogleFonts.inter(color: FlugoColors.textSecond, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('Seja o primeiro a dizer oi! 👋',
                          style: GoogleFonts.inter(
                            color: FlugoColors.textSecond.withValues(alpha: 0.5), fontSize: 13)),
                      ]));
                    }

                    return ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final m = messages[i];
                        final isMine   = currentUid.isNotEmpty && m.userId == currentUid;
                        final showDate = i == 0 || !_sameDay(messages[i-1].timestamp, m.timestamp);
                        // Agrupamento: mesma pessoa, ≤ 3 min, mensagem anterior não deletada
                        final prev = i > 0 ? messages[i - 1] : null;
                        final isGrouped = !showDate &&
                            prev != null &&
                            !prev.deleted &&
                            !m.deleted &&
                            prev.userId == m.userId &&
                            (m.timestamp - prev.timestamp) < 180000;
                        return Column(children: [
                          if (showDate) _DateDivider(timestamp: m.timestamp),
                          MessageBubble(
                            message: m,
                            isMine: isMine,
                            isGrouped: isGrouped,
                            onReply: _onReply,
                            currentUserId: currentUid),
                        ]);
                      },
                    );
                  },
                ),

                // ── Botão "ir à última mensagem" ──
                if (_showScrollBtn)
                  Positioned(
                    bottom: 16, right: 16,
                    child: _ScrollToBottomButton(onTap: _scrollToBottom),
                  ),
              ],
            ),
          ),

          // ── Reply preview ──
          if (_replyTo != null)
            Container(
              decoration: BoxDecoration(
                color: FlugoColors.appBar,
                border: Border(
                  top: BorderSide(color: FlugoColors.primary.withValues(alpha: 0.3)),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Ícone de resposta
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: FlugoColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.reply_rounded,
                      color: FlugoColors.primary, size: 17),
                  ),
                  const SizedBox(width: 10),
                  // Barra verde + conteúdo
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
                      decoration: BoxDecoration(
                        color: FlugoColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          left: BorderSide(color: FlugoColors.primary, width: 3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(children: [
                            const Icon(Icons.reply_rounded,
                              size: 11, color: FlugoColors.primary),
                            const SizedBox(width: 3),
                            Text('Respondendo a ${_replyTo!.userName}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                                color: FlugoColors.primary,
                                letterSpacing: 0.1,
                              )),
                          ]),
                          const SizedBox(height: 2),
                          Text(
                            _replyTo!.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: FlugoColors.textSecond,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Botão fechar
                  GestureDetector(
                    onTap: () => setState(() => _replyTo = null),
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: FlugoColors.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded,
                        size: 15, color: FlugoColors.textSecond),
                    ),
                  ),
                ],
              ),
            ),

          if (_error != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: FlugoColors.error.withValues(alpha: 0.15),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: FlugoColors.error, size: 16),
                const SizedBox(width: 8),
                Text(_error!, style: const TextStyle(color: FlugoColors.error, fontSize: 13)),
              ]),
            ),

          // ── Input bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: FlugoColors.appBar,
              border: Border(top: BorderSide(color: FlugoColors.border))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: Container(
                    decoration: BoxDecoration(
                      color: FlugoColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: FlugoColors.border)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: TextField(
                        controller: _controller, focusNode: _focusNode,
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.inter(fontSize: 14.5, color: FlugoColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Mensagem',
                          hintStyle: GoogleFonts.inter(
                            color: FlugoColors.textHint, fontSize: 14.5),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _hasText ? FlugoColors.primary : FlugoColors.surfaceAlt,
                  shape: BoxShape.circle),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: (_sending || !_hasText) ? null : _send,
                    child: _sending
                        ? const Center(child: SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: FlugoColors.onPrimary)))
                        : Icon(Icons.send_rounded, size: 20,
                            color: _hasText ? FlugoColors.onPrimary : FlugoColors.textSecond),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  bool _sameDay(int a, int b) {
    final da = DateTime.fromMillisecondsSinceEpoch(a);
    final db = DateTime.fromMillisecondsSinceEpoch(b);
    return da.year == db.year && da.month == db.month && da.day == db.day;
  }
}

// ── Botão "ir à última mensagem" (chevrons animados) ─────────────────────
class _ScrollToBottomButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ScrollToBottomButton({required this.onTap});
  @override
  State<_ScrollToBottomButton> createState() => _ScrollToBottomButtonState();
}

class _ScrollToBottomButtonState extends State<_ScrollToBottomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double>   _bounce;

  @override
  void initState() {
    super.initState();
    _anim   = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: 5)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounce,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _bounce.value),
        child: child,
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: FlugoColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: FlugoColors.primary.withValues(alpha: 0.4),
                blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: const Icon(Icons.keyboard_double_arrow_down_rounded,
            color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

// ── Date Divider ─────────────────────────────────────────────────────────
class _DateDivider extends StatelessWidget {
  final int timestamp;
  const _DateDivider({required this.timestamp});

  @override
  Widget build(BuildContext context) {
    final dt  = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    String label;
    if (_sd(dt, now)) {
      label = 'Hoje';
    } else if (_sd(dt, now.subtract(const Duration(days: 1)))) {
      label = 'Ontem';
    } else {
      label = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(child: Container(height: 1, color: FlugoColors.border)),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: FlugoColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FlugoColors.border)),
          child: Text(label,
            style: GoogleFonts.inter(fontSize: 11, color: FlugoColors.textSecond)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: FlugoColors.border)),
      ]),
    );
  }

  bool _sd(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}