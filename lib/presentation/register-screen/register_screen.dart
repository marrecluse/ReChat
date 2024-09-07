import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_chat_app/presentation/chat-screen/chat_screen.dart';
import 'package:my_chat_app/presentation/home-page/home_page.dart';
import 'package:my_chat_app/presentation/login-screen/login_screen.dart';
import 'package:my_chat_app/utils/appAssets.dart';
import 'package:my_chat_app/utils/constants/constants.dart';
import 'package:my_chat_app/utils/extension.dart';
import 'package:my_chat_app/utils/utils.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key, required this.isRegistering}) : super(key: key);

  static Route<void> route({bool isRegistering = false}) {
    return MaterialPageRoute(
      builder: (context) => RegisterPage(isRegistering: isRegistering),
    );
  }

  final bool isRegistering;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true; // To toggle the visibility of the password

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  File? _selectedProfilePic;

  Future<void> _pickProfilePic() async {
    final picker = ImagePicker();
    var status = await Permission.photos.status;
    if (!status.isGranted) {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedProfilePic = File(pickedFile.path);
        });
      }
    } else {
      context.showErrorSnackBar(message: "Permisson not granted");
    }
  }

  Future<void> _signUp() async {
    // Call this method when you want to hide the keyboard
                  FocusScope.of(context).unfocus();

     final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
          
   

    final email = _emailController.text;
    final password = _passwordController.text;
    final username = _usernameController.text;

    try {
      // Sign up the user
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (response.user != null) {
        final userId = response.user!.id;

        String? profilePicUrl;

        // Upload profile picture if selected
        if (_selectedProfilePic != null) {
          final profilePicFile = _selectedProfilePic!;
          final fileExt = profilePicFile.path.split('.').last;
          final fileName = '${userId}_profile.$fileExt';
          final filePath = 'user_profiles/$fileName';

          final storageResponse = await supabase.storage
              .from('user_avatars')
              .upload(filePath, profilePicFile);
          profilePicUrl =
              supabase.storage.from('user_avatars').getPublicUrl(filePath);
        }

        // Insert the user information into the 'users' table
        final insertResponse = await supabase.from('users').insert({
          'id': userId,
          'email': email,
          'name': username,
          'profile_url': profilePicUrl,
        });

        // Navigate to the home page
        Navigator.of(context)
            .pushAndRemoveUntil(HomePage.route(), (route) => false);
      } else {
        context.showErrorSnackBar(message: 'Sign up failed');
        setState(() {
          _isLoading = false;
        });
      }
    } on AuthException catch (error) {
      context.showErrorSnackBar(message: error.message);
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      context.showErrorSnackBar(
          message: 'An unexpected error occurred: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!
        .copyWith(color: theme.colorScheme.onPrimary);
    return SafeArea(
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text('Register'),
        // ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Wrap(children: [
                            Text(
                              'Sign',
                              style: style.copyWith(
                                  fontWeight: FontWeight.w200,
                                  color: theme.colorScheme.primary),
                            ),
                            Text(
                              'Up',
                              style: style.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary),
                            )
                          ]),
                          Text(
                            "Create an account, it's free",
                          ),
                          10.height,
                          GestureDetector(
                            onTap: _pickProfilePic,
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey.shade300,
                              backgroundImage: _selectedProfilePic != null
                                  ? FileImage(_selectedProfilePic!)
                                  : AssetImage(defaultAvatar),
                            ),
                          ),
                          10.height,
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              label: Text('Email'),
                            ),
                            validator: ValidatorUtils.validateEmail,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          formSpacer,
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility, color: theme.primaryColor,
                                ),
                                onPressed: () {
                                  // Toggle password visibility
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              label: Text('Password'),
                            ),
                            validator: ValidatorUtils.validatePassword,
                          ),
                          formSpacer,
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              label: Text('Username'),
                            ),
                            validator: ValidatorUtils.validateUsername,
                          ),
                          formSpacer,
                          _isLoading
                              ? CircularProgressIndicator(
                                  strokeWidth: 2,
                                )
                              : ElevatedButton(
                                  onPressed: _isLoading ? null : _signUp,
                                  child: Text(
                                    'Register',
                                    style: style.copyWith(
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                          formSpacer,
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(LoginPage.route());
                            },
                            child: const Text('I already have an account'),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
