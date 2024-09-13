import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_chat_app/presentation/login-screen/login_screen.dart';
import 'package:my_chat_app/presentation/providers/state_providers.dart';
import 'package:my_chat_app/utils/constants/constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const ProfilePage(),
    );
  }

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  File? _selectedProfilePic;
  bool _isLoggingOut = false; // State variable for loading

  @override
  void initState() {
    super.initState();

    //    SchedulerBinding.instance.addPostFrameCallback((_) {
    //   final userProvider = Provider.of<UserProvider>(context, listen: false);
    //   setState(() {
    //     _usernameController.text= userProvider.user!.name;
    //   });
    // });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePic() async {
    final picker = ImagePicker();
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      status = await Permission.photos.request();
    }

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedProfilePic = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _usernameController.text = userProvider.user!.name;

    return Stack(children: [
      Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () async {
                setState(() {
                  _isLoggingOut = true; // Show loader during logout
                });

                try {
                  await supabase.auth.signOut();

                  // Clear user data from SharedPreferences (if needed)
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear(); // Or remove specific keys if you need
                  // Navigate to the login page and remove all previous routes
                  Navigator.of(context).pushAndRemoveUntil(
                    LoginPage.route(),
                    (route) => false,
                  );
                } catch (error) {
                  print('Logout error: $error');
                } finally {
                  setState(() {
                    _isLoggingOut = false; // Hide loader after logging out
                  });
                }
              },
              icon: Icon(Icons.logout),
            ),
          ],
          title: Text(
            'Profile',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickProfilePic,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _selectedProfilePic != null
                      ? FileImage(_selectedProfilePic!)
                      : (userProvider.user!.profile_url != null
                          ? NetworkImage(userProvider.user!.profile_url)
                              as ImageProvider
                          : null),
                  child: _selectedProfilePic == null &&
                          userProvider.user!.profile_url == null
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      // profileProvider.updateUsername(value);
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller:
                      TextEditingController(text: userProvider.user!.email),
                  decoration: const InputDecoration(labelText: 'Email'),
                  readOnly: true, // Email is generally not editable
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final userId = supabase.auth.currentUser!.id;
                  String? profilePicUrl;

                  // Upload profile picture if selected
                  if (_selectedProfilePic != null) {
                    final profilePicFile = _selectedProfilePic!;
                    final fileExt = profilePicFile.path.split('.').last;
                    final fileName = '${userId}_profile.$fileExt';
                    final filePath = 'user_profiles/$fileName';

                    try {
                      // Check if there's an existing file and delete it before uploading the new one
                      await supabase.storage
                          .from('user_avatars')
                          .remove(['user_profiles/$fileName']);

                      // Upload the new profile picture
                      await supabase.storage
                          .from('user_avatars')
                          .upload(filePath, profilePicFile);

                      // Get the public URL of the uploaded file
                      final response = supabase.storage
                          .from('user_avatars')
                          .getPublicUrl(filePath);
                      profilePicUrl = response;
                    } catch (error) {
                      context.showErrorSnackBar(
                          message: "Failed to update profile picture: $error");
                      return;
                    }
                  }

                  // Update profile in Supabase database
                  final updates = {
                    'id': userId,
                    if (profilePicUrl != null) 'profile_url': profilePicUrl,
                    'name': _usernameController.text,
                    // Add other fields to update like email if needed
                  };

                  try {
                    await supabase
                        .from('users')
                        .update(updates)
                        .eq('id', userId);
                    context.showSnackBar(
                        message: "Profile updated successfully");
                    userProvider.fetchUser();
                  } catch (error) {
                    context.showErrorSnackBar(
                        message: "Failed to update profile: $error");
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
        ),
      ),
      if (_isLoggingOut) ...[
        // Blur effect
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
          child: Container(
            color: Colors.black.withOpacity(0.2), // Slight overlay color
          ),
        ),
        // Loader in the center
        Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ]
    ]);
  }
}
