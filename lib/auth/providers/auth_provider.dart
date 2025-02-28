import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Auth status enum to track authentication state
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  authenticating,
  error,
}

/// This provider is temporarily modified to always return authenticated status
/// The real implementation will be added later
class AuthProvider extends ChangeNotifier {
  // Private variables
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;
  
  // Constructor
  AuthProvider() {
    // For now, just set status to authenticated without actual auth
    _status = AuthStatus.authenticated;
    debugPrint("DEBUG [AuthProvider]: Bypassing authentication for development");
  }
  
  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => true; // Always return true for now
  
  // This method will be properly implemented later
  Future<void> signIn(String email, String password) async {
    // No implementation needed for now
    _status = AuthStatus.authenticated;
    notifyListeners();
  }
  
  // This method will be properly implemented later
  Future<void> signUp(String email, String password, String name) async {
    // No implementation needed for now
    _status = AuthStatus.authenticated;
    notifyListeners();
  }
  
  // This method will be properly implemented later
  Future<void> signOut() async {
    // For development, we'll just print a message
    debugPrint("DEBUG [AuthProvider]: Sign out requested (ignored for now)");
  }

  // This method will check auth status later
  // For now it always returns authenticated
  Future<AuthStatus> checkAuthStatus() async {
    debugPrint("DEBUG [AuthProvider]: Auth check bypassed - returning authenticated");
    _status = AuthStatus.authenticated;
    notifyListeners();
    return _status;
  }
}
