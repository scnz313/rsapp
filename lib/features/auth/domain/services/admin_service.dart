import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  // Private constructor to prevent instantiation
  AdminService._();
  
  // List of admin emails
  static const List<String> _adminEmails = [
    'trashbin2605@gmail.com',
    // Add other admin emails as needed
  ];

  /// Check if a user has admin privileges
  static bool isUserAdmin(User? user) {
    if (user == null || user.email == null) return false;
    return _adminEmails.contains(user.email!.toLowerCase());
  }
}
