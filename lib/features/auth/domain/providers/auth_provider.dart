import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../../core/utils/app_logger.dart';
import '../enums/auth_status.dart'; // Fixed import
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/google_auth_service.dart';

/// Provider for authentication state and operations
class AuthProvider with ChangeNotifier {
  static const String _tag = 'AuthProvider';
  
  /// Authentication status
  AuthStatus _status = AuthStatus.initial;
  AuthStatus get status => _status;
  
  /// Current user from Firebase Authentication
  firebase_auth.User? _user;
  firebase_auth.User? get user => _user;
  
  /// User model with additional app-specific data
  UserModel? _userModel;
  UserModel? get userModel => _userModel;
  
  /// Error message if authentication fails
  String? _error;
  String? get error => _error;
  
  /// Whether authentication is in progress
  bool _isLoading = false;
  final bool _rememberMe = false; // Made field final
  
  /// Whether user is currently authenticated
  bool get isAuthenticated => _user != null;
  
  /// Whether auth is in loading state
  bool get isLoading => _isLoading;
  
  /// Auth service that handles Firebase Authentication operations
  final AuthService _authService;
  
  /// Google auth service for social sign-in
  final GoogleAuthService _googleAuthService;
  
  /// Constructor with optional service injections for testing
  AuthProvider({
    AuthService? authService,
    GoogleAuthService? googleAuthService,
  }) : 
    _authService = authService ?? AuthService(),
    _googleAuthService = googleAuthService ?? GoogleAuthService();
  
  /// Check authentication status on app start
  Future<void> checkAuthStatus() async {
    DebugLogger.auth('Checking authentication status');
    _setLoading(true);
    
    try {
      // Get current Firebase user
      final currentUser = _authService.getCurrentUser();
      
      if (currentUser != null) {
        _user = currentUser;
        await _fetchUserModel();
        _status = AuthStatus.authenticated;
        DebugLogger.auth('User is authenticated: ${_user?.email}');
      } else {
        _status = AuthStatus.unauthenticated;
        DebugLogger.auth('User is not authenticated');
      }
    } catch (e) {
      _status = AuthStatus.error;
      _error = 'Failed to check authentication status';
      DebugLogger.error('Auth status check failed', e);
    } finally {
      _setLoading(false);
    }
  }
  
  /// Sign in with email and password
  Future<bool> signIn(String email, String password, {bool rememberMe = false}) async {
    _setLoading(true);
    _error = null;
    
    try {
      final user = await _authService.signInWithEmailAndPassword(email, password);
      if (user != null) {
        _user = user;
        await _fetchUserModel();
        _status = AuthStatus.authenticated;
        DebugLogger.auth('User signed in: ${user.email}');
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to sign in';
        _status = AuthStatus.error;
        DebugLogger.error('Sign in failed - no user returned');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _handleAuthError(e);
      _status = AuthStatus.error;
      DebugLogger.error('Sign in failed', e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Register with email and password
  Future<bool> register(String email, String password, String displayName) async {
    _setLoading(true);
    _error = null;
    
    try {
      final user = await _authService.createUserWithEmailAndPassword(email, password);
      if (user != null) {
        // Update display name
        await _authService.updateUserProfile(displayName: displayName);
        
        // Get updated user
        _user = _authService.getCurrentUser();
        
        // Create user document in Firestore
        final userMap = {
          'email': email,
          'displayName': displayName,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        };
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .set(userMap, SetOptions(merge: true));
            
        await _fetchUserModel();
        _status = AuthStatus.authenticated;
        DebugLogger.auth('User registered: $email');
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to register user';
        _status = AuthStatus.error;
        DebugLogger.error('Registration failed - no user returned');
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _handleAuthError(e);
      _status = AuthStatus.error;
      DebugLogger.error('Registration failed', e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _error = null;
    
    try {
      DebugLogger.auth('Starting Google sign in flow');
      final user = await _googleAuthService.signInWithGoogle();
      
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
        
        // Create or update user document in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
              'email': user.email,
              'displayName': user.displayName,
              'photoURL': user.photoURL,
              'lastLogin': FieldValue.serverTimestamp(),
              'role': 'user',
            }, SetOptions(merge: true));
        
        await _fetchUserModel();
        DebugLogger.auth('Google sign in successful');
        _setLoading(false); // Set loading to false before notifying
        notifyListeners();
        return true;
      }
      _setLoading(false);
      _error = 'Google sign in cancelled';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _setLoading(false);
      _error = _handleAuthError(e);
      _status = AuthStatus.unauthenticated;
      DebugLogger.error('Google sign in failed', e);
      notifyListeners();
      return false;
    }
  }
  
  /// Sign out current user
  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await _authService.signOut();
      _user = null;
      _userModel = null;
      _status = AuthStatus.unauthenticated;
      DebugLogger.auth('User signed out');
    } catch (e) {
      _error = 'Failed to sign out';
      DebugLogger.error('Sign out failed', e);
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
  
  /// Fetch user model from Firestore based on current Firebase user
  Future<void> _fetchUserModel() async {
    if (_user == null) return;
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        _userModel = UserModel.fromMap({
          'id': _user!.uid,
          'email': _user!.email,
          ...doc.data()!,
        });
      } else {
        // Create basic user model if not in Firestore yet
        _userModel = UserModel(
          id: _user!.uid,
          email: _user!.email ?? '',
          displayName: _user!.displayName,
          photoURL: _user!.photoURL,
        );
      }
    } catch (e) {
      AppLogger.e(_tag, 'Failed to fetch user model', e);
    }
  }
  
  /// Helper to update loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Helper to update error state
  void _setError(String? errorMessage) {
    _error = errorMessage;
    if (errorMessage != null) {
      _status = AuthStatus.error;
    }
    notifyListeners();
  }
  
  /// Helper function to handle common Firebase auth errors
  String _handleAuthError(dynamic error) {
    if (error is firebase_auth.FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password.';
        case 'email-already-in-use':
          return 'Email is already in use.';
        case 'invalid-email':
          return 'Email is invalid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many requests. Try again later.';
        default:
          return error.message ?? 'An unknown error occurred.';
      }
    }
    return 'An unexpected error occurred.';
  }
}
