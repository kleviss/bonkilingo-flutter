import 'package:flutter/cupertino.dart';
import 'app_colors.dart';

/// Helper to ensure all text is readable with proper colors
class CupertinoTextOverrides {
  // Text style for forms
  static const TextStyle inputText = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
  );

  // Text style for labels
  static const TextStyle labelText = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // Text style for body
  static const TextStyle bodyText = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 15,
  );

  // Text style for secondary info
  static const TextStyle secondaryText = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 14,
  );

  // Text style for buttons
  static const TextStyle buttonText = TextStyle(
    color: CupertinoColors.white,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  CupertinoTextOverrides._();
}

