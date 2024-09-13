import 'package:flutter/material.dart';
import 'package:my_chat_app/data/user-model.dart';

import 'package:my_chat_app/presentation/home-page/home_page.dart';
import 'package:my_chat_app/presentation/providers/state_providers.dart';
import 'package:my_chat_app/presentation/register-screen/register_screen.dart';
import 'package:my_chat_app/utils/constants/constants.dart';
import 'package:my_chat_app/utils/extension.dart';
import 'package:my_chat_app/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(builder: (context) => const LoginPage());
  }

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true; // To toggle the visibility of the password

  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _signIn() async {
    // Call this method when you want to hide the keyboard
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response.user != null) {
        final userId = response.user!.id;
        final userDataResponse =
            await supabase.from('users').select().eq('id', userId).single();

        final userData =
            UserModel.fromMap(userDataResponse as Map<String, dynamic>);
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        userProvider.setUser(userData);

        //save user data to shared prefs
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);
        await prefs.setString('userName', userData.name);
        await prefs.setString('profile_url', userData.profile_url);
      }

      // Reset Bottom Navigation state
      final bottomNavigationProvider =
          Provider.of<BottomNavigationProvider>(context, listen: false);
      bottomNavigationProvider.updateIndex(0); // Reset to the default index

      Navigator.of(context)
          .pushAndRemoveUntil(HomePage.route(), (route) => false);
    } on AuthException catch (error) {
      context.showErrorSnackBar(message: error.message);
      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      context.showErrorSnackBar(
          message: 'Unexpected error occurred: ${error.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Sign In')),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Form(
              key: _formKey,
              child: Column(
                // padding: formPadding,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 50, child: Image.asset(defaultAvatar)),
                  const SizedBox(
                    height: 30,
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: ValidatorUtils.validateEmail,
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
                                : Icons.visibility,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            // Toggle password visibility
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        labelText: 'Password'),
                  ),
                  formSpacer,
                  _isLoading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2,
                        )
                      : ElevatedButton(
                          onPressed: _signIn,
                          child: const Text('Login'),
                        ),
                  10.height,
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).push(RegisterPage.route());
                      },
                      child: const Text('Create an account'))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
