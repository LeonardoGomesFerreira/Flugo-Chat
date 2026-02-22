import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app.dart';
import '../../core/formatters.dart';
import 'chat_service.dart';
import 'message_model.dart';

class MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final bool isMine;
  final bool isGrouped;
  final Function(ChatMessage) onReply;
  final String currentUserId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.isGrouped = false,
    required this.onReply,
    required this.currentUserId,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  final _service = ChatService();

  static const _palette = [
    Color(0xFF22C55E), Color(0xFF60A5FA), Color(0xFFFB923C),
    Color(0xFFA78BFA), Color(0xFFF472B6), Color(0xFF34D399),
    Color(0xFFFBBF24), Color(0xFF38BDF8),
  ];

  Color _userColor(String uid) =>
      _palette[uid.hashCode.abs() % _palette.length];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 220));
    _scale = Tween<double>(begin: 0.88, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.message.readBy.containsKey(widget.currentUserId)) {
        _service.markAsRead(widget.message.id);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<ReadInfo> get _readers => widget.message.readBy.values
      .where((r) => r.uid != widget.message.userId)
      .toList();

  String get _readCountLabel {
    final n = _readers.length;
    if (n == 0) return '';
    return n > 99 ? '99+' : '$n';
  }

  void _showOptions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MessageOptionsSheet(
        message: widget.message,
        isMine: widget.isMine,
        readerCount: _readers.length,
        accentColor: _userColor(widget.message.userId),
        onReply: () { Navigator.pop(context); widget.onReply(widget.message); },
        onEdit: widget.isMine && !widget.message.deleted ? () {
          Navigator.pop(context);
          _showEditDialog(context, widget.message);
        } : null,
        onDelete: widget.isMine && !widget.message.deleted ? () {
          Navigator.pop(context);
          _confirmDelete(context, widget.message.id);
        } : null,
        onViewReaders: () {
          Navigator.pop(context);
          _showReadersDialog(context, widget.message);
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, ChatMessage msg) {
    final ctrl = TextEditingController(text: msg.text);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FlugoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Editar mensagem',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700,
                color: FlugoColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLines: null,
          style: const TextStyle(color: FlugoColors.textPrimary),
          decoration: InputDecoration(
            filled: true,
            fillColor: FlugoColors.surfaceAlt,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FlugoColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: FlugoColors.primary, width: 1.5)),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar',
                  style: GoogleFonts.inter(color: FlugoColors.textSecond))),
          ElevatedButton(
            onPressed: () {
              final newText = ctrl.text.trim();
              if (newText.isNotEmpty && newText != msg.text) {
                _service.editMessage(msg.id, newText);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FlugoColors.primary,
              foregroundColor: FlugoColors.onPrimary,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String msgId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FlugoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Apagar mensagem',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700,
                color: FlugoColors.textPrimary)),
        content: Text('A mensagem será apagada para todos.',
            style: GoogleFonts.inter(color: FlugoColors.textSecond)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar',
                  style: GoogleFonts.inter(color: FlugoColors.textSecond))),
          TextButton(
            onPressed: () { _service.deleteMessage(msgId); Navigator.pop(context); },
            child: Text('Apagar',
                style: GoogleFonts.inter(
                    color: FlugoColors.error, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showReadersDialog(BuildContext context, ChatMessage msg) {
    final readers = _readers;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: FlugoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: [
          const Icon(Icons.done_all_rounded, color: FlugoColors.primary, size: 20),
          const SizedBox(width: 8),
          Text('Visualizações',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700,
                  color: FlugoColors.textPrimary)),
        ]),
        content: readers.isEmpty
            ? Text('Ninguém visualizou ainda.',
                style: GoogleFonts.inter(color: FlugoColors.textSecond))
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${readers.length} ${readers.length == 1 ? 'visualização' : 'visualizações'}',
                    style: GoogleFonts.inter(fontSize: 13,
                        color: FlugoColors.primary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: SingleChildScrollView(
                      child: Column(
                        children: readers.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(children: [
                            _MiniAvatar(name: r.name, photoUrl: r.photoUrl,
                                color: _userColor(r.uid)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(r.name,
                                style: GoogleFonts.inter(
                                    color: FlugoColors.textPrimary,
                                    fontSize: 14, fontWeight: FontWeight.w500))),
                          ]),
                        )).toList(),
                      ),
                    ),
                  ),
                ],
              ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Fechar',
                  style: GoogleFonts.inter(color: FlugoColors.primary))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMine    = widget.isMine;
    final isGrouped = widget.isGrouped;
    final msg       = widget.message;

    if (msg.deleted) return _DeletedBubble(isMine: isMine);

    final bubbleColor = isMine ? FlugoColors.msgMine : FlugoColors.msgOther;
    final accentColor = isMine ? FlugoColors.primary : _userColor(msg.userId);

    // Bordas estilo WhatsApp: quando agrupado, canto do remetente fica menor
    final radius = BorderRadius.only(
      topLeft:     Radius.circular(isGrouped && !isMine ? 4 : 16),
      topRight:    Radius.circular(isGrouped && isMine  ? 4 : 16),
      bottomLeft:  Radius.circular(isMine ? 16 : 4),
      bottomRight: Radius.circular(isMine ? 4  : 16),
    );

    final readerCount = _readers.length;
    final countLabel  = _readCountLabel;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Dismissible(
          key: Key('swipe_${msg.id}'),
          direction: DismissDirection.startToEnd,
          confirmDismiss: (_) async { widget.onReply(msg); return false; },
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: FlugoColors.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle),
              child: const Icon(Icons.reply_rounded,
                  color: FlugoColors.primary, size: 20),
            ),
          ),
          child: GestureDetector(
            onLongPress: () => _showOptions(context),
            child: Padding(
              // Agrupado: espaçamento menor entre mensagens da mesma pessoa
              padding: EdgeInsets.only(
                top:    isGrouped ? 1.5 : 6,
                bottom: 1.5,
                left:   isMine ? 60 : 0,
                right:  isMine ? 0  : 60,
              ),
              child: Row(
                mainAxisAlignment:
                    isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Avatar: aparece só na primeira mensagem do grupo ou se não agrupado
                  if (!isMine) ...[
                    if (isGrouped)
                      const SizedBox(width: 38) // espaço = avatar (32) + gap (6)
                    else
                      StreamBuilder<Map<String, dynamic>?>(
                        stream: _service.userProfileStream(msg.userId),
                        builder: (context, snap) {
                          final livePhotoUrl = snap.data?['photoUrl'] as String?;
                          return _Avatar(
                            name: msg.userName,
                            color: accentColor,
                            // Usa foto ao vivo do Firebase, cai na foto da mensagem se não tiver
                            photoUrl: (livePhotoUrl != null && livePhotoUrl.isNotEmpty)
                                ? livePhotoUrl
                                : msg.userPhotoUrl,
                          );
                        },
                      ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                      decoration: BoxDecoration(
                        color: bubbleColor,
                        borderRadius: radius,
                        border: Border.all(
                          color: isMine
                              ? FlugoColors.primary.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Nome: só na primeira do grupo (não agrupado) e não é minha
                          if (!isMine && !isGrouped)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(msg.userName,
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12.5,
                                      color: accentColor)),
                            ),

                          // Reply preview
                          if (msg.replyToId != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                                border: Border(
                                  left: BorderSide(
                                      color: _userColor(msg.replyToUserName ?? msg.replyToId!),
                                      width: 3)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(msg.replyToUserName ?? 'Usuário',
                                      style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11.5,
                                          color: _userColor(msg.replyToUserName ?? msg.replyToId!))),
                                  const SizedBox(height: 1),
                                  Text(msg.replyToText ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: FlugoColors.textSecond)),
                                ],
                              ),
                            ),

                          Text(msg.text,
                              style: GoogleFonts.inter(
                                  fontSize: 14.5,
                                  color: FlugoColors.textPrimary,
                                  height: 1.4)),

                          const SizedBox(height: 3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (msg.edited)
                                Text('editado  ',
                                    style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: FlugoColors.textSecond.withValues(alpha: 0.6),
                                        fontStyle: FontStyle.italic)),
                              Text(formatTimeFromMillis(msg.timestamp),
                                  style: GoogleFonts.inter(
                                      fontSize: 10.5,
                                      color: FlugoColors.textSecond.withValues(alpha: 0.7))),
                              if (isMine) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  readerCount > 0
                                      ? Icons.done_all_rounded
                                      : Icons.done_rounded,
                                  size: 14,
                                  color: readerCount > 0
                                      ? FlugoColors.primary
                                      : FlugoColors.textSecond),
                                if (countLabel.isNotEmpty) ...[
                                  const SizedBox(width: 2),
                                  Text(countLabel,
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: FlugoColors.primary,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ],
                            ],
                          ),
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

// ─── Bottom sheet ─────────────────────────────────────────────────────────
class _MessageOptionsSheet extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final int readerCount;
  final Color accentColor;
  final VoidCallback onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onViewReaders;

  const _MessageOptionsSheet({
    required this.message, required this.isMine, required this.readerCount,
    required this.accentColor, required this.onReply,
    this.onEdit, this.onDelete, required this.onViewReaders,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: FlugoColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border(left: BorderSide(color: accentColor, width: 3))),
            child: Row(children: [
              Expanded(child: Text(message.text, maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      color: FlugoColors.textPrimary, fontSize: 13))),
            ]),
          ),
          const SizedBox(height: 4),
          const Divider(color: Colors.white10, height: 1),
          _Option(icon: Icons.reply_rounded, label: 'Responder',
              color: FlugoColors.primary, onTap: onReply),
          _Option(
            icon: Icons.done_all_rounded,
            label: readerCount > 0
                ? '${readerCount > 99 ? "99+" : readerCount} ${readerCount == 1 ? "visualização" : "visualizações"}'
                : 'Sem visualizações ainda',
            color: readerCount > 0 ? FlugoColors.primary : FlugoColors.textSecond,
            onTap: onViewReaders),
          if (onEdit != null)
            _Option(icon: Icons.edit_rounded, label: 'Editar mensagem',
                color: const Color(0xFF60A5FA), onTap: onEdit!),
          if (onDelete != null) ...[
            const Divider(color: Colors.white10, height: 1),
            _Option(icon: Icons.delete_rounded, label: 'Apagar para todos',
                color: FlugoColors.error, onTap: onDelete!),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _Option({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 19)),
          const SizedBox(width: 14),
          Text(label, style: GoogleFonts.inter(fontSize: 15,
              fontWeight: FontWeight.w500, color: FlugoColors.textPrimary)),
        ]),
      ),
    );
  }
}

// ─── Mensagem apagada ─────────────────────────────────────────────────────
class _DeletedBubble extends StatelessWidget {
  final bool isMine;
  const _DeletedBubble({required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 2, bottom: 2,
          left: isMine ? 80 : 0, right: isMine ? 0 : 80),
      child: Row(
        mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: FlugoColors.surfaceAlt.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.block_rounded, size: 14,
                  color: FlugoColors.textSecond.withValues(alpha: 0.5)),
              const SizedBox(width: 6),
              Text('Mensagem apagada',
                  style: GoogleFonts.inter(fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: FlugoColors.textSecond.withValues(alpha: 0.5))),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Avatar com foto em tempo real ───────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String name;
  final Color color;
  final String? photoUrl;

  const _Avatar({required this.name, required this.color, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ')
        .where((p) => p.isNotEmpty).take(2)
        .map((p) => p[0].toUpperCase()).join();

    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5)),
      child: ClipOval(
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? Image.network(photoUrl!, fit: BoxFit.cover,
                key: ValueKey(photoUrl), // força recarregar quando URL muda
                errorBuilder: (context, error, stack) =>
                    _InitialsCircle(initials: initials, color: color))
            : _InitialsCircle(initials: initials, color: color),
      ),
    );
  }
}

// ─── Avatar mini (leitores) ───────────────────────────────────────────────
class _MiniAvatar extends StatelessWidget {
  final String name; final String? photoUrl; final Color color;
  const _MiniAvatar({required this.name, this.photoUrl, required this.color});

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ')
        .where((p) => p.isNotEmpty).take(2)
        .map((p) => p[0].toUpperCase()).join();

    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5)),
      child: ClipOval(
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? Image.network(photoUrl!, fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                    _InitialsCircle(initials: initials, color: color))
            : _InitialsCircle(initials: initials, color: color),
      ),
    );
  }
}

class _InitialsCircle extends StatelessWidget {
  final String initials; final Color color;
  const _InitialsCircle({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Text(initials,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
