import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:my_chat_app/presentation/chat-screen/chat_screen.dart';
import 'package:my_chat_app/utils/constants/constants.dart';
import 'package:my_chat_app/utils/extension.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({Key? key}) : super(key: key);

  static Route<void> route() {
    return MaterialPageRoute(builder: (context) => const ForgotPage());
  }

  @override
  _ForgotPageState createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
 
final TextEditingController _emailController = TextEditingController();
  @override
  void dispose() {
   
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Sign In')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          // padding: formPadding,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

          Text('Forgot Your Password ?',style: Theme.of(context).textTheme.displayMedium!.copyWith(
color: Theme.of(context).colorScheme.primary
          ),),
            formSpacer,
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              obscureText: true,
            ),
            formSpacer,
            ElevatedButton(
              onPressed:  (){},
              child: const Text('Send'),
            ),
              
          ],
        ),
      ),
    );
  }
}
