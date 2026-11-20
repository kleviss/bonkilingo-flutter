import 'package:flutter/cupertino.dart';

/// Brand palette taken from the Bonkilingo app icon: the sunny-to-tangerine
/// background, the green and orange books, the pink ribbon and the dark
/// speech bubbles. Used for the colour graphics (glows, highlights, demo
/// cards) on top of the neutral UI colours in [AppColors].
class BrandColors {
  static const Color sunny = Color(0xFFFFD84D);
  static const Color tangerine = Color(0xFFFF9A3D);
  static const Color leaf = Color(0xFF7ED957);
  static const Color ribbon = Color(0xFFF0477A);
  static const Color ink = Color(0xFF1C1C1E);

  /// Warm off-white page background for brand screens in light mode.
  static const Color cream = Color(0xFFFFF8EC);

  /// Near-black page background for brand screens in dark mode.
  static const Color night = Color(0xFF111113);

  static const LinearGradient iconGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [sunny, tangerine],
  );

  BrandColors._();
}

/// Surface and text colours for brand-styled screens, per theme.
class BrandPalette {
  final bool isDark;
  const BrandPalette(this.isDark);

  static const Color red = Color(0xFFE5484D);
  static const Color green = Color(0xFF30A46C);

  Color get card => isDark ? const Color(0xFF1E1E21) : const Color(0xE6FFFFFF);
  Color get cardSunken =>
      isDark ? const Color(0xFF2A2A2E) : const Color(0xFFF4EFE6);
  Color get text => isDark ? const Color(0xFFF5F5F7) : BrandColors.ink;
  Color get muted => isDark ? const Color(0xFFA1A1A6) : const Color(0xFF7A746B);
  Color get greenBg =>
      isDark ? const Color(0xFF173B2A) : const Color(0xFFD9F5E3);
  Color get redBg => isDark ? const Color(0xFF3F1C1E) : const Color(0xFFFFE1E1);

  /// Soft lift for cards on the cream background; none in dark mode.
  List<BoxShadow>? get cardShadow => isDark
      ? null
      : [
          BoxShadow(
            color: const Color(0xFF8A5A00).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ];
}
