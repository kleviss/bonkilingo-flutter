import 'package:flutter/cupertino.dart';

/// Modern dark mode color palette - sophisticated and not dull!
class AppDarkColors {
  // Primary Colors - Brighter in dark mode for better contrast
  static const Color primary = Color(0xFFFBBF24); // Yellow-400 (brighter!)
  static const Color primaryGlow = Color(0xFFFEF08A); // Yellow-200 (for glows)
  static const Color primaryDark = Color(0xFFD97706); // Amber-600

  // Background Colors - Not pure black! Modern dark grays with depth
  static const Color background = Color(0xFF0F0F0F); // Very dark gray (not black)
  static const Color backgroundSecondary = Color(0xFF1A1A1A); // Slightly lighter
  static const Color backgroundTertiary = Color(0xFF242424); // Card backgrounds
  static const Color backgroundElevated = Color(0xFF2D2D2D); // Elevated cards
  
  // Gradient backgrounds for visual interest
  static const Color gradientStart = Color(0xFF1A1A1A);
  static const Color gradientEnd = Color(0xFF0F0F0F);

  // Text Colors - Softer whites for better readability
  static const Color textPrimary = Color(0xFFF5F5F5); // Off-white (easier on eyes)
  static const Color textSecondary = Color(0xFFB3B3B3); // Warm gray
  static const Color textTertiary = Color(0xFF737373); // Muted gray
  static const Color textDisabled = Color(0xFF525252); // Very muted

  // Semantic Colors - Vibrant for dark backgrounds
  static const Color success = Color(0xFF34D399); // Green-400 (brighter)
  static const Color successLight = Color(0xFF065F46); // Dark green bg
  static const Color successGlow = Color(0xFF10B981); // For highlights
  
  static const Color error = Color(0xFFF87171); // Red-400 (brighter)
  static const Color errorLight = Color(0xFF7F1D1D); // Dark red bg
  
  static const Color warning = Color(0xFFFBBF24); // Amber-400
  static const Color warningLight = Color(0xFF78350F); // Dark amber
  
  static const Color info = Color(0xFF60A5FA); // Blue-400 (brighter)
  static const Color infoLight = Color(0xFF1E3A8A); // Dark blue bg
  static const Color infoGlow = Color(0xFF3B82F6); // For accents

  // UI Element Colors - Subtle but visible
  static const Color border = Color(0xFF404040); // Visible dark border
  static const Color borderLight = Color(0xFF2A2A2A); // Subtle border
  static const Color divider = Color(0xFF333333); // Divider lines
  static const Color shadow = Color(0x40000000); // Deeper shadows
  static const Color highlight = Color(0x0AFFFFFF); // Subtle highlights
  
  // Glass morphism effects
  static const Color glass = Color(0x1AFFFFFF); // Frosted glass effect
  static const Color glassStrong = Color(0x33FFFFFF); // Stronger glass

  // Interactive states
  static const Color hover = Color(0xFF2F2F2F); // Hover state
  static const Color pressed = Color(0xFF3A3A3A); // Pressed state
  static const Color focused = Color(0xFF404040); // Focus ring

  // Special accent colors
  static const Color accentPurple = Color(0xFFA78BFA); // Purple-400
  static const Color accentBlue = Color(0xFF60A5FA); // Blue-400
  static const Color accentGreen = Color(0xFF34D399); // Green-400
  static const Color accentOrange = Color(0xFFFB923C); // Orange-400

  // Learning Module Colors - Darker, muted versions for dark mode
  static const Color orangeDark = Color(0xFF3A2817); // Dark orange bg
  static const Color blueDark = Color(0xFF1E2A3A); // Dark blue bg
  static const Color greenDark = Color(0xFF1A2F25); // Dark green bg
  static const Color yellowDark = Color(0xFF3A3420); // Dark yellow bg
  static const Color purpleDark = Color(0xFF2D2438); // Dark purple bg

  AppDarkColors._();
}

