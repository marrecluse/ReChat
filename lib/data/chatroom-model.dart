class ChatroomModel {
  final String id;
  final String name;
  final String description;
  final int totalMembers;
  final String lastMessage;
  final DateTime createdAt;
  final DateTime? lastActivity;
  final String creatorId;
  final String? avatarUrl;

  ChatroomModel({
    required this.id,
    required this.name,
    required this.lastMessage,
    this.description = '',
    this.totalMembers = 0,
    required this.createdAt,
    this.lastActivity,
    required this.creatorId,
    this.avatarUrl,
  });

  // Convert a ChatroomModel to a map for Supabase operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'total_members': totalMembers,
      'created_at': createdAt.toIso8601String(),
      'last_activity': lastActivity?.toIso8601String(),
      'creator_id': creatorId,
      'last_message': lastMessage,
      'avatar_url': avatarUrl,
    };
  }

  // Convert a map from Supabase to a ChatroomModel
  factory ChatroomModel.fromMap(Map<String, dynamic> map) {
    return ChatroomModel(
      id: map['id'] as String,
      name: map['name'] as String,
      lastMessage: map['last_message'] as String,
      description: map['description'] as String? ?? '',
      totalMembers: map['total_members'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastActivity: map['last_activity'] != null
          ? DateTime.parse(map['last_activity'] as String)
          : null,
      creatorId: map['creator_id'] as String,
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}
