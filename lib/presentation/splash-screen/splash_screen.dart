import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:my_chat_app/data/user-model.dart';
import 'package:my_chat_app/presentation/chat-screen/chat_screen.dart';
import 'package:my_chat_app/presentation/home-page/home_page.dart';
import 'package:my_chat_app/presentation/login-screen/login_screen.dart';
import 'package:my_chat_app/presentation/register-screen/register_screen.dart';
import 'package:my_chat_app/utils/appAssets.dart';
import 'package:my_chat_app/utils/constants/constants.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_chat_app/presentation/providers/state_providers.dart';

/// Page to redirect users to the appropriate page depending on the initial auth state
class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  SplashPageState createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Simulate a loading delay for splash screen
    await Future.delayed(Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final userProvider = Provider.of<UserProvider>(context,listen: false);    
    if (userId != null) {
      // User is logged in, navigate to ChatScreen
      final response = await supabase.from("users").select().eq('id', userId).single();
      final userData = UserModel.fromMap(response);
              userProvider.setUser(userData);


        Navigator.of(context)
          .pushAndRemoveUntil(HomePage.route(), (route) => false);
    } else {
      // No userId found, navigate to RegisterScreen
        Navigator.of(context)
          .pushAndRemoveUntil(LoginPage.route(), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If you use Provider, you can access user data or loading states here
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      body: Center(
        child: Container(
          height: 420,
          width: 420,
          child: Lottie.asset(AppAssets.lottie_mobile_chat),
        ),
      ),
    );
  }
}
