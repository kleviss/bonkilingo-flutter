import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'app_colors.dart';
import 'dark_colors.dart';

/// Smart theme helper that provides context-aware colors
class ThemeHelper {
  final ThemeMode themeMode;

  const ThemeHelper(this.themeMode);

  bool get isDark => themeMode == ThemeMode.dark;

  // Adaptive colors that work in both themes
  Color get background => isDark ? AppDarkColors.background : AppColors.background;
  Color get backgroundSecondary => isDark ? AppDarkColors.backgroundSecondary : AppColors.backgroundSecondary;
  Color get backgroundTertiary => isDark ? AppDarkColors.backgroundTertiary : AppColors.backgroundTertiary;
  Color get backgroundElevated => isDark ? AppDarkColors.backgroundElevated : AppColors.background;
  Color get cardBackground => isDark ? AppDarkColors.backgroundTertiary : CupertinoColors.white;

  Color get textPrimary => isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
  Color get textSecondary => isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;
  Color get textTertiary => isDark ? AppDarkColors.textTertiary : AppColors.textTertiary;

  Color get primary => isDark ? AppDarkColors.primary : AppColors.primary;
  Color get primaryLight => isDark ? AppDarkColors.primaryGlow : AppColors.primaryLight;

  Color get success => isDark ? AppDarkColors.success : AppColors.success;
  Color get successLight => isDark ? AppDarkColors.successLight : AppColors.successLight;

  Color get error => isDark ? AppDarkColors.error : AppColors.error;
  Color get errorLight => isDark ? AppDarkColors.errorLight : AppColors.errorLight;

  Color get info => isDark ? AppDarkColors.info : AppColors.info;
  Color get infoLight => isDark ? AppDarkColors.infoLight : AppColors.infoLight;

  Color get border => isDark ? AppDarkColors.border : AppColors.border;
  Color get divider => isDark ? AppDarkColors.divider : AppColors.divider;

  // Learning module colors - adapt to theme
  Color get orangeModule => isDark ? AppDarkColors.orangeDark : AppColors.orangeLight;
  Color get blueModule => isDark ? AppDarkColors.blueDark : AppColors.blueLight;
  Color get greenModule => isDark ? AppDarkColors.greenDark : AppColors.greenLight;
  Color get yellowModule => isDark ? AppDarkColors.yellowDark : AppColors.yellowLight;
  Color get purpleModule => isDark ? AppDarkColors.purpleDark : AppColors.purpleLight;

  // Card decoration - adaptive with subtle elevation
  BoxDecoration get cardDecoration => BoxDecoration(
    color: isDark ? AppDarkColors.backgroundTertiary : CupertinoColors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: isDark ? AppDarkColors.borderLight : AppColors.border,
      width: isDark ? 0.5 : 1,
    ),
    boxShadow: isDark
        ? [
            // Subtle glow effect in dark mode
            BoxShadow(
              color: AppDarkColors.highlight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ]
        : [],
  );

  // Elevated card (for important content)
  BoxDecoration get elevatedCardDecoration => BoxDecoration(
    gradient: isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppDarkColors.backgroundElevated,
              AppDarkColors.backgroundTertiary,
            ],
          )
        : null,
    color: isDark ? null : CupertinoColors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: isDark ? AppDarkColors.border : AppColors.border,
      width: isDark ? 0.5 : 1,
    ),
    boxShadow: isDark
        ? [
            // Stronger glow for elevated cards
            BoxShadow(
              color: primary.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ]
        : [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
  );

  // Input field decoration
  BoxDecoration get inputDecoration => BoxDecoration(
    color: isDark ? AppDarkColors.backgroundSecondary : CupertinoColors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: isDark ? AppDarkColors.border : AppColors.border,
    ),
  );

  // Text styles
  TextStyle get bodyText => TextStyle(
    color: textPrimary,
    fontSize: 15,
  );

  TextStyle get labelText => TextStyle(
    color: textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  TextStyle get secondaryText => TextStyle(
    color: textSecondary,
    fontSize: 14,
  );

  TextStyle get captionText => TextStyle(
    color: textTertiary,
    fontSize: 12,
  );
}

