
import 'package:flutter/material.dart';
import 'package:my_chat_app/data/profiles-model.dart';
import 'package:my_chat_app/presentation/providers/friends-provider.dart';
import 'package:my_chat_app/presentation/providers/state_providers.dart';
import 'package:my_chat_app/presentation/splash-screen/splash_screen.dart';
import 'package:my_chat_app/utils/constants/constants.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // TODO: Replace credentials with your own
    url: 'https://xwrmwmyeedixjwkbivwu.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh3cm13bXllZWRpeGp3a2Jpdnd1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjQ3NTkzMDcsImV4cCI6MjA0MDMzNTMwN30.-TkxGvr8qnCOIRKwScV7pgVu58wVxtt9ZSWIqJyi1Ck',
  );

  final userProvider = UserProvider();
  await userProvider.loadUserFromPrefs();
  runApp( MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_)=> BottomNavigationProvider()),
      ChangeNotifierProvider(create: (_)=> UserProvider()),
      ChangeNotifierProvider(create: (_)=> ChatroomProvider()),
      ChangeNotifierProvider(create: (_)=> FriendsProvider()),
      // ChangeNotifierProvider(create: (_)=> ProfileProvider()),
    ],
    child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Chat App',
      theme: appTheme,
      home: const SplashPage(),
    );
  }
}
