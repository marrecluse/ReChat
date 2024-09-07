class UserModel {
  final String id;
  final String name;
  final String email;
  final String profile_url;
  final List<String> chatrooms_joined;
  final List<String> friends_added;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profile_url = '',
    this.chatrooms_joined = const [],
    this.friends_added = const [],
  });

  // Factory constructor to create a UserModel from Supabase data
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      profile_url: map['profile_url'] as String? ?? '',
      chatrooms_joined: List<String>.from(map['chatrooms_joined'] ?? []),
      friends_added: List<String>.from(map['friends_added'] ?? []),
    );
  }

  // Convert a UserModel to a map for Supabase operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profile_url': profile_url,
      'chatrooms_joined': chatrooms_joined,
      'friends_added': friends_added,
    };
  }
}
