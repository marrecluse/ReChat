import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class for common functions and constants used in the chat application.
class Utils {
  // Formats a DateTime object into a readable string format (e.g., "12:30 PM").
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  // Shows a snack bar with the given message in the current context.
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Validates an email address and returns true if valid.
  static bool isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
    );
    return emailRegex.hasMatch(email);
  }

  // Validates if a string is not null and not empty.
  static bool isNotEmpty(String? text) {
    return text != null && text.trim().isNotEmpty;
  }

  // Converts a color hex string (e.g., "#0FCCCE") to a Color object.
  static Color hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex'; // Add FF for the alpha value if not provided.
    }
    return Color(int.parse(hex, radix: 16));
  }

  // Show a confirmation dialog with OK and Cancel buttons.
  static Future<bool?> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Generates a random string of a given length.
  static String generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = new Random();
    return List.generate(length, (index) => chars[(chars.length * random.nextInt(100)).floor()]).join('');
  }

  // Converts a Firebase Timestamp to a DateTime object.
  static DateTime timestampToDateTime(dynamic timestamp) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp.seconds * 1000);
  }

  // Converts a DateTime object to a Firebase Timestamp.
  static int dateTimeToTimestamp(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch ~/ 1000;
  }
}
class ValidatorUtils {
  // Email validation function
  static String? validateEmail(String? val) {
    if (val == null || val.isEmpty) {
      return 'Email is required';
    }

    // Regular expression for validating email format
    String emailPattern =
        r'^[a-zA-Z0-9.a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regex = RegExp(emailPattern);

    if (!regex.hasMatch(val)) {
      return 'Enter a valid email address';
    }
    return null; // Return null if no error
  }

  // Password validation function
  static String? validatePassword(String? val) {
    if (val == null || val.isEmpty) {
      return 'Password is required';
    }

    // Password must be at least 8 characters long and contain at least one number
    if (val.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    // Password should contain at least one digit
    if (!RegExp(r'[0-9]').hasMatch(val)) {
      return 'Password must contain at least one number';
    }

    return null; // Return null if no error
  }

  // Username validation function
  static String? validateUsername(String? val) {
    if (val == null || val.isEmpty) {
      return 'Username is required';
    }

    // Username must be at least 4 characters long
    if (val.length < 4) {
      return 'Username must be at least 4 characters long';
    }

    // Username should contain only alphanumeric characters
    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(val)) {
      return 'Username can only contain letters and numbers';
    }

    return null; // Return null if no error
  }
}
