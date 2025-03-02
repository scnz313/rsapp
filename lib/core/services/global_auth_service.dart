import '../utils/debug_logger.dart';
import '../utils/navigation_logger.dart';
// Make sure this matches the import in main.dart
import '../../features/auth/domain/providers/auth_provider.dart';

/// A global service that holds authentication provider
class GlobalAuthService {
  static final GlobalAuthService _instance = GlobalAuthService._internal();
  
  factory GlobalAuthService() {
    return _instance;
  }
  
  GlobalAuthService._internal();
  
  final AuthProvider authProvider = AuthProvider();
  
  Future<void> initialize() async {
    NavigationLogger.log(
      NavigationEventType.providerAccess,
      'Initializing GlobalAuthService',
    );
    try {
      final currentStatus = authProvider.status;
      NavigationLogger.log(
        NavigationEventType.providerAccess,
        'GlobalAuthService initialized',
        data: 'status: $currentStatus, isAuthenticated: ${authProvider.isAuthenticated}',
      );
    } catch (e) {
      NavigationLogger.log(
        NavigationEventType.providerError,
        'Failed to initialize GlobalAuthService',
        data: e,
      );
    }
  }
  
  Future<bool> signIn(String email, String password, {bool rememberMe = false}) async {
    NavigationLogger.log(
      NavigationEventType.providerAccess,
      'Attempting sign in via GlobalAuthService',
      data: {'email': email, 'rememberMe': rememberMe},
    );
    try {
      await authProvider.signIn(email, password, rememberMe: rememberMe);
      NavigationLogger.log(
        NavigationEventType.providerAccess,
        'Sign in successful',
        data: 'isAuthenticated: ${authProvider.isAuthenticated}',
      );
      return true;
    } catch (e) {
      NavigationLogger.log(
        NavigationEventType.providerError,
        'Sign in failed',
        data: e,
      );
      rethrow;
    }
  }

  // Update the signOut method to be more robust
  Future<void> signOut() async {
    NavigationLogger.log(
      NavigationEventType.providerAccess,
      'Attempting sign out via GlobalAuthService',
    );
    try {
      await authProvider.signOut();
      NavigationLogger.log(
        NavigationEventType.providerAccess,
        'Sign out successful',
      );
    } catch (e) {
      NavigationLogger.log(
        NavigationEventType.providerError,
        'Sign out failed in GlobalAuthService',
        data: e,
      );
      DebugLogger.error('GlobalAuthService: Sign out failed', e);
      rethrow; // Re-throw to allow UI to handle and display error
    }
  }

  // Getters for auth status
  bool get isAuthenticated => authProvider.isAuthenticated;
  bool get isLoading => authProvider.isLoading;
  String? get error => authProvider.error;
}
