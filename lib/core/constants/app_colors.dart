import 'package:flutter/material.dart';

class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();
  
  // Light theme colors - Green and white theme
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF2E7D32),        // Forest Green - primary color
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF4CAF50), // Medium Green
    onPrimaryContainer: Colors.white,
    secondary: Color(0xFF00796B),      // Teal accent
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFF80CBC4), // Light teal
    onSecondaryContainer: Colors.black,
    tertiary: Color(0xFF8BC34A),       // Light Green
    onTertiary: Colors.black,
    tertiaryContainer: Color(0xFFDCEDC8),
    onTertiaryContainer: Colors.black,
    error: Color(0xFFD32F2F),          // Error red
    onError: Colors.white,
    errorContainer: Color(0xFFFFCDD2),
    onErrorContainer: Color(0xFF601010),
    background: Colors.white,
    onBackground: Colors.black,
    surface: Colors.white,
    onSurface: Colors.black,
    outline: Color(0xFFBDBDBD),
    surfaceVariant: Color(0xFFF5F5F5),
    onSurfaceVariant: Color(0xFF616161),
  );
  
  // Dark theme colors - Green-based dark theme
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF81C784),        // Lighter green for dark theme
    onPrimary: Colors.black,
    primaryContainer: Color(0xFF1B5E20),
    onPrimaryContainer: Colors.white,
    secondary: Color(0xFF26A69A),      // Teal green for dark theme
    onSecondary: Colors.black,
    secondaryContainer: Color(0xFF00695C),
    onSecondaryContainer: Colors.white,
    tertiary: Color(0xFFAED581),       // Light green accent for dark theme
    onTertiary: Colors.black,
    tertiaryContainer: Color(0xFF33691E),
    onTertiaryContainer: Colors.white,
    error: Color(0xFFEF9A9A),          // Lighter error red for dark theme
    onError: Colors.black,
    errorContainer: Color(0xFF9B0000),
    onErrorContainer: Colors.white,
    background: Color(0xFF121212),     // Dark background
    onBackground: Colors.white,
    surface: Color(0xFF1E1E1E),        // Dark surface
    onSurface: Colors.white,
    outline: Color(0xFF757575),
    surfaceVariant: Color(0xFF303030),
    onSurfaceVariant: Color(0xFFE0E0E0),
  );
  
  // Update additional properties as well
  static const Color primarySeed = Color(0xFF2E7D32);  // Forest Green as seed
  static const Color tertiaryColor = Color(0xFF8BC34A); // Light Green
  static const Color text = Colors.black87;
  static const Color textLight = Colors.black54;
  static const Color surfaceDark = Color(0xFF121212);
  
  // Common colors
  static const Color transparent = Colors.transparent;
  static const Color black = Colors.black;
  static const Color white = Colors.white;
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color darkGrey = Color(0xFF616161);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50); // Green - matches our primary theme
  static const Color warning = Color(0xFFFFC107); // Amber
  static const Color info = Color(0xFF26A69A);    // Teal - matches our secondary
  static const Color error = Color(0xFFD32F2F);   // Red
}
