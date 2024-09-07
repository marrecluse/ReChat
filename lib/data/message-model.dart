class Message {
  Message({
    required this.id,
    required this.sender_id,
    required this.content,
    required this.createdAt,
    required this.isMine, required String chatroomId,
  });

  /// ID of the message
  final String id;

  /// ID of the user who posted the message
  final String sender_id;

  /// Text content of the message
  final String content;

  /// Date and time when the message was created
  final DateTime createdAt;

  /// Whether the message is sent by the user or not.
  final bool isMine;

  Message.fromMap({
    required Map<String, dynamic> map,
    required String myUserId,
  })  : id = map['id'],
        sender_id = map['sender_id'],
        content = map['content'],
        createdAt = DateTime.parse(map['created_at']),
        // isMine = myUserId == map['profile_id'];
        isMine = myUserId == map['sender_id'];
}
