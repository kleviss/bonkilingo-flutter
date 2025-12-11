import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/dark_colors.dart';

// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const String _key = 'theme_mode';
  
  ThemeModeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? false;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = newMode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, newMode == ThemeMode.dark);
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, mode == ThemeMode.dark);
  }

  bool get isDark => state == ThemeMode.dark;
}

// Light theme
class AppThemes {
  static const CupertinoThemeData lightTheme = CupertinoThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    barBackgroundColor: AppColors.background,
    brightness: Brightness.light,
    primaryContrastingColor: AppColors.textPrimary,
    textTheme: CupertinoTextThemeData(
      textStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
      ),
      actionTextStyle: TextStyle(
        color: AppColors.primary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      navTitleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      navLargeTitleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 34,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  // Dark theme - Modern, sophisticated, not dull!
  static const CupertinoThemeData darkTheme = CupertinoThemeData(
    primaryColor: AppDarkColors.primary, // Brighter yellow for dark mode
    scaffoldBackgroundColor: AppDarkColors.background, // Very dark gray (not pure black)
    barBackgroundColor: AppDarkColors.backgroundSecondary, // Subtle elevation
    brightness: Brightness.dark,
    primaryContrastingColor: AppDarkColors.textPrimary, // Off-white
    textTheme: CupertinoTextThemeData(
      // Main text - off-white for eye comfort
      textStyle: TextStyle(
        color: AppDarkColors.textPrimary, // F5F5F5 - soft white
        fontSize: 16,
      ),
      // Action/button text - bright yellow
      actionTextStyle: TextStyle(
        color: AppDarkColors.primary, // Bright yellow
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      // Navigation title - crisp and clear
      navTitleTextStyle: TextStyle(
        color: AppDarkColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4, // iOS-style tight tracking
      ),
      // Large title - bold and prominent
      navLargeTitleTextStyle: TextStyle(
        color: AppDarkColors.textPrimary,
        fontSize: 34,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
      // Tab label
      tabLabelTextStyle: TextStyle(
        color: AppDarkColors.textSecondary,
        fontSize: 10,
        letterSpacing: -0.24,
      ),
    ),
  );

  AppThemes._();
}

