import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import '../auth/auth_service.dart';
import 'message_model.dart';

class ChatService {
  ChatService._internal() {
    // Cache e sincronização (WhatsApp-like)
    _messagesRef.keepSynced(true);
    _usersRef.keepSynced(true);

    // Offset do servidor para timestamps consistentes entre usuários
    _serverOffsetSub = FirebaseDatabase.instance
        .ref('.info/serverTimeOffset')
        .onValue
        .listen((event) {
      final v = event.snapshot.value;
      if (v is int) {
        _serverOffsetMs = v;
      } else if (v is num) {
        _serverOffsetMs = v.toInt();
      } else {
        _serverOffsetMs = 0;
      }
    });
  }

  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;

  final DatabaseReference _messagesRef = FirebaseDatabase.instance.ref('messages');
  final DatabaseReference _usersRef = FirebaseDatabase.instance.ref('users');

  StreamSubscription<DatabaseEvent>? _serverOffsetSub;
  int _serverOffsetMs = 0;

  void dispose() {
    _serverOffsetSub?.cancel();
    _serverOffsetSub = null;
  }

  int _serverNowMs() => DateTime.now().millisecondsSinceEpoch + _serverOffsetMs;

  Query messagesQuery({int limit = 200}) {
    return _messagesRef.orderByChild('timestamp').limitToLast(limit);
  }

  void syncUserProfile() {
    final user = AuthService().currentUser;
    if (user == null) return;

    _usersRef.child(user.uid).set({
      'name': user.displayName ?? user.email?.split('@').first ?? 'Usuário',
      'photoUrl': user.photoURL ?? '',
      'uid': user.uid,
    });
  }

  Stream<Map<String, dynamic>?> userProfileStream(String uid) {
    return _usersRef.child(uid).onValue.map((event) {
      final val = event.snapshot.value;
      if (val == null) return null;
      if (val is Map) return Map<String, dynamic>.from(val);
      return null;
    });
  }

  Future<void> sendMessage(String text, {ChatMessage? replyTo}) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final ref = _messagesRef.push();

    await ref.set({
      'text': trimmed,
      'userId': user.uid,
      'userName': user.displayName ?? user.email?.split('@').first ?? 'Usuário',
      'userPhotoUrl': user.photoURL ?? '',
      'timestamp': _serverNowMs(),
      'serverTimestamp': ServerValue.timestamp,
      if (replyTo != null) 'replyToId': replyTo.id,
      if (replyTo != null) 'replyToText': replyTo.text,
      if (replyTo != null) 'replyToUserName': replyTo.userName,
      'deleted': false,
      'edited': false,
      'readBy': {
        user.uid: {
          'name': user.displayName ?? user.email?.split('@').first ?? 'Usuário',
          if ((user.photoURL ?? '').isNotEmpty) 'photoUrl': user.photoURL,
        }
      },
    });

    syncUserProfile();
  }

  Future<void> markAsRead(String messageId) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final info = ReadInfo(
      uid: user.uid,
      name: user.displayName ?? user.email?.split('@').first ?? 'Usuário',
      photoUrl: user.photoURL,
    );

    await _messagesRef
        .child(messageId)
        .child('readBy')
        .child(user.uid)
        .set(info.toMap());
  }

  Future<void> editMessage(String messageId, String newText) async {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;

    await _messagesRef.child(messageId).update({
      'text': trimmed,
      'edited': true,
    });
  }

  /// ✅ Apagar para todos (WhatsApp-like)
  /// Soft delete: marca deleted=true e substitui texto por placeholder.
  Future<void> deleteMessage(String messageId) async {
    final user = AuthService().currentUser;
    if (user == null) return;

    final ref = _messagesRef.child(messageId);

    // Confere se existe e se o autor é o usuário atual (igual WhatsApp)
    final ownerSnap = await ref.child('userId').get();
    final ownerId = ownerSnap.value?.toString();

    // Se não existe mensagem (ou id errado), não faz nada
    if (ownerId == null || ownerId.isEmpty) return;

    // Só o autor pode "apagar para todos"
    if (ownerId != user.uid) return;

    // Atualiza: isso dispara o stream e sua UI já mostra _DeletedBubble
    await ref.update({
      'deleted': true,
      'isDeleted': true, // compat extra
      'text': 'Mensagem apagada',
      'edited': false,
      'deletedAt': ServerValue.timestamp,
      'deletedBy': user.uid,

      // remove preview de reply (opcional)
      'replyToId': null,
      'replyToText': null,
      'replyToUserName': null,
    });
  }

  List<ChatMessage> parseSnapshot(DataSnapshot snapshot) {
    final val = snapshot.value;
    if (val == null) return [];

    final map = Map<dynamic, dynamic>.from(val as dynamic);
    final items = <ChatMessage>[];

    map.forEach((key, value) {
      if (value is Map) {
        items.add(ChatMessage.fromMap(key.toString(), value));
      }
    });

    // Ordenação estável: timestamp ascendente + id (tie-break)
    items.sort((a, b) {
      final t = a.timestamp.compareTo(b.timestamp);
      if (t != 0) return t;
      return a.id.compareTo(b.id);
    });

    return items;
  }
}