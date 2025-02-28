import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/auth/providers/auth_provider.dart';
import '/features/home/screens/home_screen.dart';

/// This wrapper component checks authentication state and redirects accordingly
/// Currently modified to always show the HomeScreen and bypass authentication
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('AuthWrapper: Building...');
    
    // Skip authentication for now and always return the HomeScreen
    return const HomeScreen();
    
    // The real implementation will look like this:
    /*
    final authProvider = Provider.of<AuthProvider>(context);
    
    switch (authProvider.status) {
      case AuthStatus.authenticated:
        return const HomeScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
      case AuthStatus.authenticating:
        return const LoadingScreen();
      case AuthStatus.error:
        return const LoginScreen(); // Could show an error screen instead
      case AuthStatus.initial:
      default:
        return const SplashScreen();
    }
    */
  }
}
