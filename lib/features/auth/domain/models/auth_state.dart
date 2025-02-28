import '../enums/auth_status.dart';

class AuthState {
  final AuthStatus status;
  final String? error;
  final bool isLoading;
  final bool isAdmin;

  const AuthState({
    this.status = AuthStatus.unauthenticated, // Replace with an actual value from your AuthStatus enum
    this.error,
    this.isLoading = false,
    this.isAdmin = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? error,
    bool? isLoading,
    bool? isAdmin,
  }) {
    return AuthState(
      status: status ?? this.status,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
