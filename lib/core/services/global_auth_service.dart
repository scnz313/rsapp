import '../utils/debug_logger.dart';
import '../utils/navigation_logger.dart';
// Remove unused import: '../utils/logger.dart'
import '../../features/auth/domain/providers/auth_provider.dart';

/// A global service that holds authentication provider
class GlobalAuthService {
  static final GlobalAuthService _instance = GlobalAuthService._internal();
  
  factory GlobalAuthService() {
    return _instance;
  }
  
  GlobalAuthService._internal();
  
  AuthProvider? _authProvider;
  
  Future<void> initialize() async {
    NavigationLogger.log(
      NavigationEventType.providerAccess,
      'STARTING GlobalAuthService initialization',
    );
    
    try {
      DebugLogger.info('Creating new AuthProvider instance');
      _authProvider = AuthProvider();
      
      if (_authProvider == null) {
        DebugLogger.error('CRITICAL: _authProvider is null after assignment');
      } else {
        DebugLogger.info('AuthProvider instance created successfully');
      }
      
      DebugLogger.info('Checking auth status...');
      // Fix: Remove unnecessary null-aware operator since we just checked for null
      await _authProvider!.checkAuthStatus();
      
      final status = _authProvider?.status?.toString() ?? 'UNKNOWN';
      final isAuth = _authProvider?.isAuthenticated.toString() ?? 'UNKNOWN';
      DebugLogger.info('Auth check complete: Status=$status, isAuthenticated=$isAuth');
      
      NavigationLogger.log(
        NavigationEventType.providerAccess,
        'GlobalAuthService initialization COMPLETED',
        data: {'status': status, 'isAuthenticated': isAuth},
      );
    } catch (e) {
      DebugLogger.error('ERROR initializing GlobalAuthService', e);
      // Create a backup provider if needed
      if (_authProvider == null) {
        DebugLogger.info('Creating BACKUP AuthProvider');
        _authProvider = AuthProvider();
      }
    }
  }
  
  Future<bool> signIn(String email, String password, {bool rememberMe = false}) async {
    try {
      await _authProvider!.signIn(email, password, rememberMe: rememberMe);
      return _authProvider!.isAuthenticated;
    } catch (e) {
      DebugLogger.error('GlobalAuthService: Sign in failed', e);
      rethrow;
    }
  }

  // Update the signOut method to delegate to AuthProvider
  Future<void> signOut() async {
    try {
      await _authProvider!.signOut();
    } catch (e) {
      DebugLogger.error('GlobalAuthService: Sign out failed', e);
      rethrow;
    }
  }

  // Getters for auth status
  bool get isAuthenticated {
    final result = _authProvider?.isAuthenticated ?? false;
    DebugLogger.info('GlobalAuthService.isAuthenticated = $result');
    return result;
  }
  bool get isLoading => _authProvider!.isLoading;
  String? get error => _authProvider!.error;

  // Add a safe getter that never returns null
  AuthProvider get authProvider {
    if (_authProvider == null) {
      DebugLogger.error('CRITICAL: Accessing null _authProvider, creating emergency instance');
      _authProvider = AuthProvider();
    }
    
    DebugLogger.info('GlobalAuthService.authProvider accessed successfully');
    return _authProvider!;
  }
}
