import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/utils/exceptions/auth_exception.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/dev_utils.dart'; // Import the dev utils
import '../../data/auth_service.dart';
import '../../domain/enums/auth_status.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Simplified AuthState class
class AuthState {
  final AuthStatus status;
  final String? error;
  final bool isLoading;
  final bool isAdmin;
  final User? user;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.error,
    this.isLoading = false,
    this.isAdmin = false,
    this.user,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? error,
    bool? isLoading,
    bool? isAdmin,
    User? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      isAdmin: isAdmin ?? this.isAdmin,
      user: user ?? this.user,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  static const String _tag = 'AuthProvider';

  final AuthService _authService = AuthService();
  AuthState _state = const AuthState();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Getters
  AuthStatus get status => _state.status;
  String? get error => _state.error;
  bool get isLoading => _state.isLoading;
  bool get isAdmin => _state.isAdmin;
  User? get user => _state.user;
  AuthState get state => _state;
  bool get isAuthenticated => 
    (DevUtils.isDev && DevUtils.bypassAuth) || _state.status == AuthStatus.authenticated;

  // Initialize auth state
  AuthProvider() {
    _initAuthState();
  }

  // Initialize auth state - modified to support dev mode
  Future<void> _initAuthState() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      if (DevUtils.isDev && DevUtils.bypassAuth) {
        // In dev mode with bypass enabled, simulate a logged-in user
        DevUtils.log('Using dev bypass mode for authentication');
        
        // Create a fake auth state - code will think we're logged in
        _state = _state.copyWith(
          status: AuthStatus.authenticated,
          isAdmin: true, // Set to true if you need admin access
          user: _createDevUser(),
          isLoading: false
        );
        
        notifyListeners();
        return;
      }
      
      // Normal auth flow
      final user = await _authService.refreshAuthState();
      
      if (user != null) {
        AppLogger.d(_tag, 'User authenticated: ${user.email}');
        
        // Check if admin
        bool isAdminUser = false;
        try {
          isAdminUser = await _authService.isAdmin();
        } catch (e) {
          // Continue even if admin check fails
          AppLogger.e(_tag, 'Error checking admin status', e);
        }
        
        _state = _state.copyWith(
          status: AuthStatus.authenticated,
          isAdmin: isAdminUser,
          user: user,
          isLoading: false
        );
      } else {
        AppLogger.d(_tag, 'No user authenticated');
        _state = _state.copyWith(
          status: AuthStatus.unauthenticated,
          isLoading: false
        );
      }
    } catch (e) {
      AppLogger.e(_tag, 'Error initializing auth state', e);
      _state = _state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Failed to initialize authentication',
        isLoading: false
      );
    }
    
    notifyListeners();
  }

  // Sign in method - modified for dev mode
  Future<bool> signIn(String email, String password, BuildContext context, {bool rememberMe = false}) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      if (DevUtils.isDev && DevUtils.bypassAuth) {
        // In dev mode with bypass, always succeed
        DevUtils.log('Bypassing authentication for: $email');
        
        // Simulate short delay for UI feedback
        await Future.delayed(const Duration(milliseconds: 800));
        
        _state = _state.copyWith(
          status: AuthStatus.authenticated,
          isAdmin: true, // Set to true for testing admin features
          user: _createDevUser(),
          isLoading: false,
          error: null
        );
        
        notifyListeners();
        return true;
      }
      
      // Regular auth flow
      AppLogger.d(_tag, 'Attempting sign in');
      
      // Call auth service
      final user = await _authService.signIn(email, password);
      
      if (user != null) {
        // Check if admin
        bool isAdminUser = false;
        try {
          isAdminUser = await _authService.isAdmin();
        } catch (e) {
          // Continue even if admin check fails
          AppLogger.e(_tag, 'Error checking admin status', e);
        }
        
        _state = _state.copyWith(
          status: AuthStatus.authenticated,
          isAdmin: isAdminUser,
          user: user,
          isLoading: false,
          error: null
        );
        
        AppLogger.d(_tag, 'Sign in successful');
        notifyListeners();
        return true;
      } else {
        throw AuthException('Failed to sign in');
      }
    } catch (e) {
      AppLogger.e(_tag, 'Sign in failed', e);
      _state = _state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e is AuthException ? e.message : 'Authentication failed: $e',
        isLoading: false
      );
      notifyListeners();
      return false;
    }
  }

  // Create a fake User object for development mode
  User? _createDevUser() {
    if (!DevUtils.isDev) return null;
    
    try {
      // Instead of trying to cast to User, we'll just keep this as a dynamic object
      // and modify our code to handle this special case
      DevUtils.log('Creating dev user for testing');
      
      // Return null here - we'll handle the dev user differently
      return null;
    } catch (e) {
      AppLogger.e(_tag, 'Error creating dev user', e);
      return null;
    }
  }

  // Sign up method
  Future<bool> signUp(String email, String password, BuildContext context) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
      AppLogger.d(_tag, 'Attempting sign up');
      
      // Call auth service
      final user = await _authService.signUp(email, password);
      
      if (user != null) {
        _state = _state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isLoading: false,
          error: null
        );
        
        AppLogger.d(_tag, 'Sign up successful');
        notifyListeners();
        return true;
      } else {
        throw AuthException('Failed to create account');
      }
    } catch (e) {
      AppLogger.e(_tag, 'Sign up failed', e);
      _state = _state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e is AuthException ? e.message : 'Registration failed: $e',
        isLoading: false
      );
      notifyListeners();
      return false;
    }
  }

  // Reset password method
  Future<bool> resetPassword(String email) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    
    try {
      await _authService.resetPassword(email);
      _state = _state.copyWith(isLoading: false, error: null);
      notifyListeners();
      return true;
    } catch (e) {
      _state = _state.copyWith(
        isLoading: false,
        error: e is AuthException ? e.message : 'Password reset failed: $e'
      );
      notifyListeners();
      return false;
    }
  }

  // Sign out method
  Future<void> signOut() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      await _authService.signOut();
      _state = _state.copyWith(
        user: null,
        status: AuthStatus.unauthenticated,
        isAdmin: false,
        isLoading: false
      );
    } catch (e) {
      AppLogger.e(_tag, 'Sign out failed', e);
      _state = _state.copyWith(
        error: 'Failed to sign out',
        isLoading: false
      );
    }
    
    notifyListeners();
  }
  
  // Reset error
  void resetError() {
    _state = _state.copyWith(error: null);
    notifyListeners();
  }

  // Add a method to get user ID that works in dev mode
  String? getUserId() {
    if (DevUtils.isDev && DevUtils.bypassAuth) {
      return DevUtils.devUserId;
    }
    return user?.uid;
  }

  // Save user info to shared preferences
  Future<void> _saveUserToPrefs(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_uid', user.uid);
      await prefs.setString('user_email', user.email ?? '');
      await prefs.setString('user_name', user.displayName ?? '');
      await prefs.setString('user_photo', user.photoURL ?? '');
      await prefs.setBool('user_is_admin', _state.isAdmin);
      await prefs.setString('user_role', _state.isAdmin ? 'Admin' : 'User');
    } catch (e) {
      debugPrint('Error saving user to prefs: $e');
    }
  }

  // Clear user info from shared preferences
  Future<void> _clearUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_uid');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_photo');
      await prefs.remove('user_is_admin');
      await prefs.remove('user_role');
    } catch (e) {
      debugPrint('Error clearing user from prefs: $e');
    }
  }

  // Make sure signInWithGoogle is properly defined to match the call from login_screen.dart
  Future<User?> signInWithGoogle(BuildContext context) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();
    
    try {
      // Initialize Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      // If user canceled the sign-in flow
      if (googleUser == null) {
        _state = _state.copyWith(isLoading: false);
        notifyListeners();
        return null;
      }
      
      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in with Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      _state = _state.copyWith(user: userCredential.user);
      
      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      
      if (isNewUser && _state.user != null) {
        // Create user document in Firestore for new users
        await _firestore.collection('users').doc(_state.user!.uid).set({
          'email': _state.user!.email,
          'displayName': _state.user!.displayName ?? '',
          'photoURL': _state.user!.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'provider': 'google',
          'role': 'user',
        });
      } else if (_state.user != null) {
        // Update last login for existing users
        await _firestore.collection('users').doc(_state.user!.uid).update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }
      
      _state = _state.copyWith(status: AuthStatus.authenticated);
      await _fetchUserData(); // Get additional user data
      
      _state = _state.copyWith(error: null, isLoading: false);
      notifyListeners();
      
      return _state.user;
    } catch (e) {
      _state = _state.copyWith(error: e.toString(), status: AuthStatus.error, isLoading: false);
      notifyListeners();
      return null;
    }
  }

  Future<void> _fetchUserData() async {
    // ... existing code ...
  }
}
