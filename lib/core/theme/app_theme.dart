import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primarySeed,
    scaffoldBackgroundColor: AppColors.surfaceLight,
    colorScheme: AppColors.lightColorScheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.lightColorScheme.primary,
      foregroundColor: Colors.white,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AppColors.text,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: AppColors.text,
        fontSize: 16,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData.dark().copyWith(
    primaryColor: AppColors.primarySeed,
    scaffoldBackgroundColor: AppColors.surfaceDark,
    colorScheme: AppColors.darkColorScheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceDark,
      foregroundColor: Colors.white,
    ),
    cardTheme: CardTheme(
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
