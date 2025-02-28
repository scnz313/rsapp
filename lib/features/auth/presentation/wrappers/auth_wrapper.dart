import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';  // Updated import path
import '/features/main/screens/main_container_screen.dart'; // Import the main container

/// This wrapper component checks authentication state and redirects accordingly
/// Currently modified to always show the MainContainerScreen and bypass authentication
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('AuthWrapper: Building...');
    
    // Skip authentication for now and return MainContainerScreen
    return const MainContainerScreen(initialIndex: 0);
    
    // The real implementation will look like this:
    /*
    final authProvider = Provider.of<AuthProvider>(context);
    
    switch (authProvider.status) {
      case AuthStatus.authenticated:
        return const MainContainerScreen();
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
