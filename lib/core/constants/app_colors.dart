import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Private constructor

  // Add missing color definitions
  static const Color primarySeed = Color(0xFF2E7D32);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF121212);
  static const Color text = Color(0xFF1A1A1A);
  static const Color error = Color(0xFFB00020);

  // Light Theme Color Scheme
  static final ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: const Color(0xFF2E7D32), // Green for the main color
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFADE9B7), // Light green 
    onPrimaryContainer: const Color(0xFF1A2E19),
    secondary: const Color(0xFF2196F3), // Blue
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFBBDEFB), // Light blue
    onSecondaryContainer: const Color(0xFF0D47A1),
    tertiary: const Color(0xFFFF9800), // Orange
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFFFE0B2), // Light orange
    onTertiaryContainer: const Color(0xFF854D00),
    error: const Color(0xFFB00020), // Standard Material error color
    onError: Colors.white,
    errorContainer: const Color(0xFFFDE0E0),
    onErrorContainer: const Color(0xFF5F1D1D),
    background: const Color(0xFFF5F5F5), // Slightly off white
    onBackground: const Color(0xFF1A1A1A), // Nearly black
    surface: Colors.white,
    onSurface: const Color(0xFF1A1A1A),
    surfaceVariant: const Color(0xFFEEEEEE), // Light gray
    onSurfaceVariant: const Color(0xFF636363), // Dark gray
    outline: const Color(0xFFBDBDBD), // Medium gray
    shadow: const Color(0xFF000000),
    inverseSurface: const Color(0xFF1A1A1A),
    onInverseSurface: Colors.white,
    inversePrimary: const Color(0xFF7EC488),
    surfaceTint: const Color(0xFF2E7D32),
  );

  // Dark Theme Color Scheme
  static final ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: const Color(0xFF7EC488), // Lighter green for dark theme
    onPrimary: const Color(0xFF1A2E19),
    primaryContainer: const Color(0xFF2E7D32),
    onPrimaryContainer: const Color(0xFFADE9B7),
    secondary: const Color(0xFF64B5F6), // Lighter blue for dark theme
    onSecondary: const Color(0xFF0D47A1),
    secondaryContainer: const Color(0xFF1976D2),
    onSecondaryContainer: const Color(0xFFBBDEFB),
    tertiary: const Color(0xFFFFB74D), // Lighter orange for dark theme
    onTertiary: const Color(0xFF854D00),
    tertiaryContainer: const Color(0xFFFF9800),
    onTertiaryContainer: const Color(0xFFFFE0B2),
    error: const Color(0xFFCF6679), // Dark theme error color
    onError: const Color(0xFF5F1D1D),
    errorContainer: const Color(0xFFB00020),
    onErrorContainer: const Color(0xFFFDE0E0),
    background: const Color(0xFF121212), // Dark background
    onBackground: Colors.white,
    surface: const Color(0xFF1E1E1E), // Dark surface
    onSurface: Colors.white,
    surfaceVariant: const Color(0xFF2C2C2C), // Slightly lighter dark surface
    onSurfaceVariant: const Color(0xFFBDBDBD),
    outline: const Color(0xFF636363),
    shadow: const Color(0xFF000000),
    inverseSurface: Colors.white,
    onInverseSurface: const Color(0xFF1A1A1A),
    inversePrimary: const Color(0xFF2E7D32),
    surfaceTint: const Color(0xFF7EC488),
  );

  // Common colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
  static const Color divider = Color(0xFFE0E0E0);
}
