class ReadInfo {
  final String uid;
  final String name;
  final String? photoUrl;

  ReadInfo({required this.uid, required this.name, this.photoUrl});

  factory ReadInfo.fromMap(String uid, dynamic val) {
    if (val is Map) {
      return ReadInfo(
        uid: uid,
        name: val['name']?.toString() ?? uid.substring(0, 8),
        photoUrl: val['photoUrl']?.toString(),
      );
    }
    // compatibilidade com formato antigo (bool)
    return ReadInfo(uid: uid, name: uid.substring(0, 8));
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
      };
}

class ChatMessage {
  final String id;
  final String text;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int timestamp;
  final String? replyToId;
  final String? replyToText;
  final String? replyToUserName;
  final bool deleted;
  final bool edited;
  final Map<String, ReadInfo> readBy;

  ChatMessage({
    required this.id,
    required this.text,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.timestamp,
    this.replyToId,
    this.replyToText,
    this.replyToUserName,
    this.deleted = false,
    this.edited = false,
    this.readBy = const {},
  });

  factory ChatMessage.fromMap(String id, Map<dynamic, dynamic> map) {
    final rawReadBy = map['readBy'];
    final readBy = <String, ReadInfo>{};

    if (rawReadBy is Map) {
      rawReadBy.forEach((k, v) {
        final uid = k.toString();
        readBy[uid] = ReadInfo.fromMap(uid, v);
      });
    }

    final tsRaw = map['timestamp'];
    final timestamp = (tsRaw is int)
        ? tsRaw
        : int.tryParse(tsRaw?.toString() ?? '') ?? 0;

    // ✅ compat: aceita deleted OU isDeleted
    final isDeleted = map['deleted'] == true || map['isDeleted'] == true;

    return ChatMessage(
      id: id,
      text: (map['text'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
      userName: (map['userName'] ?? '').toString(),
      userPhotoUrl: map['userPhotoUrl']?.toString(),
      timestamp: timestamp,
      replyToId: map['replyToId']?.toString(),
      replyToText: map['replyToText']?.toString(),
      replyToUserName: map['replyToUserName']?.toString(),
      deleted: isDeleted,
      edited: map['edited'] == true,
      readBy: readBy,
    );
  }

  Map<String, dynamic> toMap() => {
        'text': text,
        'userId': userId,
        'userName': userName,
        if (userPhotoUrl != null) 'userPhotoUrl': userPhotoUrl,
        'timestamp': timestamp,
        if (replyToId != null) 'replyToId': replyToId,
        if (replyToText != null) 'replyToText': replyToText,
        if (replyToUserName != null) 'replyToUserName': replyToUserName,
        'deleted': deleted,
        'isDeleted': deleted, // compat
        'edited': edited,
        'readBy': readBy.map((k, v) => MapEntry(k, v.toMap())),
      };
}