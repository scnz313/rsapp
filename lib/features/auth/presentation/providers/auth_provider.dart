import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../core/utils/exceptions/auth_exception.dart';
import '../../../../core/utils/logger.dart';
import '../../data/auth_service.dart';
import '../../domain/enums/auth_status.dart';

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
  
  // Getters
  AuthStatus get status => _state.status;
  String? get error => _state.error;
  bool get isLoading => _state.isLoading;
  bool get isAdmin => _state.isAdmin;
  User? get user => _state.user;
  AuthState get state => _state;
  bool get isAuthenticated => _state.status == AuthStatus.authenticated;

  // Initialize auth state
  AuthProvider() {
    _initAuthState();
  }

  // Initialize auth state
  Future<void> _initAuthState() async {
    _state = _state.copyWith(isLoading: true);
    notifyListeners();

    try {
      // Try to refresh auth state first before checking current user
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

  // Sign in method
  Future<bool> signIn(String email, String password, BuildContext context) async {
    _state = _state.copyWith(isLoading: true, error: null);
    notifyListeners();

    try {
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
}
