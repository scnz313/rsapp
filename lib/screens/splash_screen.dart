import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/domain/enums/auth_status.dart'; // Add this import
import '../core/utils/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await Future.delayed(const Duration(seconds: 2)); // Minimum splash duration
      if (!mounted) return;
      
      // Replace isAuthenticated with status check
      if (authProvider.status == AuthStatus.authenticated) {
        // Navigate to home
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Navigate to login
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      AppLogger.e('SplashScreen', 'Error during auth check', e);
      if (!mounted) return;
      context.pushReplacement('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your app logo or branding
            Image.asset(
              'assets/images/app_logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
