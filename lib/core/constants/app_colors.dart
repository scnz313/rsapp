import 'package:flutter/material.dart';

class AppColors {
  // Main brand colors
  static const Color primarySeed = Color(0xFF0E8E3B); // Vibrant green
  static const Color secondarySeed = Color(0xFF4CAF50); // Secondary green
  static const Color tertiaryColor = Color(0xFF81C784); // Light green
  
  static const Color text = Color(0xFF212121);
  static const Color textLight = Color(0xFF757575);
  static const Color border = Color(0xFFE0E0E0);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  
  // Surface colors
  static const Color surfaceLight = Color(0xFFF8F8F8); // Almost white for light theme
  static const Color surfaceDark = Color(0xFF121212); // Dark for dark theme

  // Color schemes
  static final ColorScheme lightColorScheme = ColorScheme.fromSeed(
    brightness: Brightness.light,
    seedColor: primarySeed,
    secondary: secondarySeed,
    tertiary: tertiaryColor,
    error: error,
    background: Colors.white,
    surface: surfaceLight,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: text,
    onSurface: text,
    onError: Colors.white,
  );

  static final ColorScheme darkColorScheme = ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: primarySeed,
    secondary: secondarySeed,
    tertiary: tertiaryColor,
    error: error,
    background: surfaceDark,
    surface: const Color(0xFF1E1E1E),
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onBackground: Colors.white,
    onSurface: Colors.white,
    onError: Colors.white,
  );
}
