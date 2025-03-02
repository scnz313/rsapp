import 'package:flutter/material.dart';

/// Utility class for showing consistent snackbars throughout the app
class SnackBarUtils {
  // Private constructor to prevent instantiation
  SnackBarUtils._();
  
  /// Shows an error SnackBar with the given message
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      // Change from floating to fixed to avoid layout issues
      behavior: SnackBarBehavior.fixed,
      duration: const Duration(seconds: 3),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  
  /// Shows a success SnackBar with the given message
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      // Change from floating to fixed
      behavior: SnackBarBehavior.fixed,
      duration: const Duration(seconds: 2),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  
  /// Shows an info SnackBar with the given message
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    final snackBar = SnackBar(
      content: Text(message),
      // Change from floating to fixed
      behavior: SnackBarBehavior.fixed,
      margin: const EdgeInsets.all(8),
      duration: const Duration(seconds: 2),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  
  /// Shows a warning SnackBar with the given message
  static void showWarningSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.orange,
          // Change from floating to fixed
          behavior: SnackBarBehavior.fixed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
