class Profile {
  Profile({
    required this.id,
    required this.username,
        this.profilePicUrl,
      required  this.email,

  });
  /// User ID of the profile
  final String id;

  /// Username of the profile
  final String username;
  final String email;

  String? profilePicUrl;

  /// Date and time when the profile was created

  Profile.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        username = map['name'],
        profilePicUrl = map['profile_url'],
        email = map['email'];

  // A method to update profile picture URL
  void updateProfilePic(String newUrl) {
    profilePicUrl = newUrl;
  }
}




