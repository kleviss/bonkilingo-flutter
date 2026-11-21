import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import '../../../core/theme/brand_colors.dart';

/// Soft rounded card on brand screens: no border, a light lift in light mode.
class BrandCard extends StatelessWidget {
  final BrandPalette palette;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  const BrandCard({
    super.key,
    required this.palette,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 22,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? palette.card,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: palette.cardShadow,
      ),
      child: child,
    );
  }
}

/// Section heading with an optional trailing widget (e.g. a "See all" link).
class BrandSectionTitle extends StatelessWidget {
  final String text;
  final BrandPalette palette;
  final Widget? trailing;

  const BrandSectionTitle(
    this.text, {
    super.key,
    required this.palette,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: palette.text,
                ),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Icon in a tinted circle, the colour-coding used across brand screens.
class BrandIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isDark;
  final double size;

  const BrandIconBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.isDark,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// A row inside a grouped [BrandCard]: leading badge, title, subtitle,
/// trailing value, and a chevron when tappable.
class BrandListRow extends StatelessWidget {
  final BrandPalette palette;
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const BrandListRow({
    super.key,
    required this.palette,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: palette.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 20, color: palette.muted),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: onTap,
      child: row,
    );
  }
}

/// Hairline between rows of a grouped card, inset past the leading badge.
class BrandRowDivider extends StatelessWidget {
  final BrandPalette palette;
  final double inset;

  const BrandRowDivider({super.key, required this.palette, this.inset = 70});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: EdgeInsets.only(left: inset),
      color: palette.muted.withValues(alpha: 0.25),
    );
  }
}

/// Secondary action: a solid ink pill (cream in dark mode), quieter than the
/// gradient [PillButton].
class SecondaryPillButton extends StatelessWidget {
  final BrandPalette palette;
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;

  const SecondaryPillButton({
    super.key,
    required this.palette,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final bg = palette.isDark ? BrandColors.cream : BrandColors.ink;
    final fg = palette.isDark ? BrandColors.ink : BrandColors.cream;
    return Semantics(
      button: true,
      enabled: enabled,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 0,
        onPressed: onPressed,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            height: height,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: fg),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
