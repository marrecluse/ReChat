// models/friend.dart
class Friend {
  final String id;
  final String userId;
  final String friendId;
  final DateTime createdAt;

  Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.createdAt,
  });

  factory Friend.fromMap(Map<String, dynamic> map) {
    return Friend(
      id: map['id'],
      userId: map['user_id'],
      friendId: map['friend_id'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}