import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

enum ThemeOption {
  light,
  dark,
  system,
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  ThemeOption _themeOption = ThemeOption.system;
  late ThemeData _themeData;
  static const String _themePreferenceKey = 'theme_preference';
  
  ThemeProvider() {
    _themeData = AppTheme.lightTheme; // Default theme
    _loadThemePreference();
  }
  
  ThemeOption get themeOption => _themeOption;
  ThemeData get themeData => _themeData;
  bool get isDarkMode => _isDarkMode;
  
  // Add this getter to convert ThemeOption to ThemeMode
  ThemeMode get themeMode {
    switch (_themeOption) {
      case ThemeOption.light:
        return ThemeMode.light;
      case ThemeOption.dark:
        return ThemeMode.dark;
      case ThemeOption.system:
        return ThemeMode.system;
    }
  }
  
  // Initialize theme based on saved preferences or system default
  Future<void> _loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(_themePreferenceKey);
      
      if (savedTheme != null) {
        _themeOption = ThemeOption.values.firstWhere(
          (e) => e.toString() == savedTheme,
          orElse: () => ThemeOption.system,
        );
      }
      
      _updateThemeData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
    }
  }
  
  // Set theme and save to preferences
  Future<void> setTheme(ThemeOption option) async {
    if (_themeOption == option) return;
    
    _themeOption = option;
    _updateThemeData();
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, option.toString());
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }
  
  // Determine and set the appropriate theme based on the selected option
  void _updateThemeData() {
    switch (_themeOption) {
      case ThemeOption.light:
        _themeData = AppTheme.lightTheme;
        break;
      case ThemeOption.dark:
        _themeData = AppTheme.darkTheme;
        break;
      case ThemeOption.system:
        final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
        _themeData = brightness == Brightness.dark ? AppTheme.darkTheme : AppTheme.lightTheme;
        break;
    }
  }
  
  // Toggle between light and dark mode (ignoring system)
  Future<void> toggleTheme() async {
    if (isDarkMode) {
      await setTheme(ThemeOption.light);
    } else {
      await setTheme(ThemeOption.dark);
    }
  }
  
  // Set dark mode directly
  void setDarkMode(bool darkMode) {
    _isDarkMode = darkMode;
    notifyListeners();
  }
}
