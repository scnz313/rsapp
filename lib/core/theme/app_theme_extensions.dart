import 'package:flutter/material.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  final Color cardBgColor;
  final Color statusBarColor;
  final Color searchBarBgColor;

  const AppThemeExtension({
    required this.cardBgColor,
    required this.statusBarColor,
    required this.searchBarBgColor,
  });

  @override
  AppThemeExtension copyWith({
    Color? cardBgColor,
    Color? statusBarColor,
    Color? searchBarBgColor,
  }) {
    return AppThemeExtension(
      cardBgColor: cardBgColor ?? this.cardBgColor,
      statusBarColor: statusBarColor ?? this.statusBarColor,
      searchBarBgColor: searchBarBgColor ?? this.searchBarBgColor,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) {
      return this;
    }
    
    return AppThemeExtension(
      cardBgColor: Color.lerp(cardBgColor, other.cardBgColor, t)!,
      statusBarColor: Color.lerp(statusBarColor, other.statusBarColor, t)!,
      searchBarBgColor: Color.lerp(searchBarBgColor, other.searchBarBgColor, t)!,
    );
  }

  static const light = AppThemeExtension(
    cardBgColor: Colors.white,
    statusBarColor: Color(0xFF0E8E3B),
    searchBarBgColor: Colors.white,
  );

  static const dark = AppThemeExtension(
    cardBgColor: Color(0xFF1E1E1E),
    statusBarColor: Color(0xFF121212),
    searchBarBgColor: Color(0xFF2C2C2C),
  );
}
