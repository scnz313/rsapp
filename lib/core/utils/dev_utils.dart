import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Add this import for Widget, Banner, BannerLocation and Color

/// Utility class for development-only features
class DevUtils {
  // Private constructor to prevent instantiation
  DevUtils._();
  
  /// Whether the app is running in development mode
  static const bool isDev = !kReleaseMode; // Changed 'final' to 'const' as suggested
  
  /// Whether to bypass Firebase Auth for testing
  /// Set this to true during development to bypass actual authentication
  static const bool bypassAuth = true;
  
  /// Fake user ID for development
  static const String devUserId = 'dev-user-123';
  
  /// Fake user email for development
  static const String devUserEmail = 'dev@example.com';
  
  /// Logs a development message with a distinct prefix
  static void log(String message) {
    if (isDev) {
      debugPrint('🛠️ DEV: $message');
    }
  }
  
  /// Shows a development banner if in dev mode
  static Widget devBanner(Widget child) {
    if (!isDev) return child;
    
    return Banner(
      message: 'DEV',
      location: BannerLocation.topEnd,
      color: const Color(0xFFFFA000),
      child: child,
    );
  }
}
