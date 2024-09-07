import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase client
final supabase = Supabase.instance.client;

final defaultAvatar=  'assets/images/defaultAvatar.png';

/// Simple preloader inside a Center widget
const preloader =
    Center(child: CircularProgressIndicator(color: Colors.orange));

/// Simple sized box to space out form elements
const formSpacer = SizedBox(width: 16, height: 16);

/// Some padding for all the forms to use
const formPadding = EdgeInsets.symmetric(vertical: 20, horizontal: 16);

/// Error message to display the user when unexpected error occurs.
const unexpectedErrorMessage = 'Unexpected error occurred.';

/// Basic theme to change the look and feel of the app
final appTheme = ThemeData(fontFamily: 'FiraSans').copyWith(
  
  primaryColorDark: Color.fromARGB(255, 11, 204, 196),
  colorScheme: ColorScheme.fromSeed(seedColor: Color(0x0FCCCE)),
  appBarTheme: const AppBarTheme(
    
    elevation: 1,
    backgroundColor: Colors.white,
    iconTheme: IconThemeData(color: Colors.black),
    titleTextStyle: TextStyle(
      fontFamily: 'FiraSans',
      color: Colors.black,
      fontSize: 18,
    ),
  ),
  primaryColor: Color(0xFF0FCCCE),
  
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      
      
      foregroundColor: Color(0xFF0FCCCE),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      
      foregroundColor: Colors.white,
      backgroundColor: Color(0xFF0FCCCE),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    floatingLabelStyle: const TextStyle(
      fontFamily: 'FiraSans',
      color: Color(0xFF0FCCCE),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Colors.grey,
        width: 2,
      ),
    ),
    focusColor: Color(0xFF0FCCCE),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(
        color: Color(0xFF0FCCCE),
        width: 2,
      ),
    ),
  ),
);


/// Set of extension methods to easily display a snackbar
extension ShowSnackBar on BuildContext {
  /// Displays a basic snackbar
  void showSnackBar({
    required String message,
    Color backgroundColor = Colors.green
  }) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
    ));
  }

  /// Displays a red snackbar indicating error
  void showErrorSnackBar({required String message}) {
    showSnackBar(message: message, backgroundColor: Colors.red);
  }
}

/// This file contains all the constants used across the chat application.

class AppConstants {
  // App-wide color scheme.
  static const Color primaryColor = Color(0xFF0FCCCE);
  static const Color accentColor = Color(0xFF00ACC1);
  static const Color backgroundColor = Color(0xFFF6F7FB);
  static const Color textColor = Color(0xFF333333);
  static const Color secondaryTextColor = Color(0xFF757575);
  static const Color errorColor = Color(0xFFB00020);

  // Default padding and spacing values.
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Text styles.
  static const TextStyle headingTextStyle = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle bodyTextStyle = TextStyle(
    fontSize: 16.0,
    color: textColor,
  );

  static const TextStyle secondaryBodyTextStyle = TextStyle(
    fontSize: 14.0,
    color: secondaryTextColor,
  );

  // Icon sizes.
  static const double smallIconSize = 20.0;
  static const double defaultIconSize = 24.0;
  static const double largeIconSize = 30.0;

  // Chat-related constants.
  static const int messageMaxLength = 1000;
  static const String defaultProfilePicture =
      'https://example.com/default_profile_pic.png';
  static const String defaultChatBackground =
      'https://example.com/default_chat_bg.png';

  // API-related constants.
  static const String apiBaseUrl = 'https://api.yourchatapp.com';
  static const int apiTimeoutDuration = 30; // seconds

  // Firebase keys and paths.
  static const String firebaseChatCollection = 'chats';
  static const String firebaseUsersCollection = 'users';
  static const String firebaseMessagesSubcollection = 'messages';

  // Strings for UI text.
  static const String appName = 'ChatApp';
  static const String welcomeMessage = 'Welcome to ChatApp!';
  static const String enterMessageHint = 'Type a message...';
  static const String loadingMessage = 'Loading...';
  static const String errorMessage = 'An error occurred, please try again.';
  static const String emptyChatMessage = 'No messages yet. Start the conversation!';

  // Other constants.
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const double chatBubbleRadius = 16.0;
  static const double chatAvatarSize = 45.0;

  // Theme-related constants.
  static const String fontFamily = 'Roboto';
}
