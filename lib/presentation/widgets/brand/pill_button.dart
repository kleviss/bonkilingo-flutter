import 'package:flutter/cupertino.dart';
import '../../../core/theme/brand_colors.dart';

/// Primary call to action: a full-width sunny-to-tangerine pill.
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    // Flat, quiet fill when disabled; a faded gradient looks muddy on dark.
    final disabledFill =
        isDark ? const Color(0xFF2A2A2E) : const Color(0xFFEDE6DA);
    final showGradient = enabled || loading;

    return Semantics(
      button: true,
      enabled: enabled,
      label: loading ? '$label, working' : label,
      excludeSemantics: true,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: enabled ? onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 56,
          decoration: BoxDecoration(
            color: showGradient ? null : disabledFill,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Container(
            height: 56,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: showGradient ? BrandColors.iconGradient : null,
              borderRadius: BorderRadius.circular(999),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: BrandColors.tangerine.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: loading
                ? const CupertinoActivityIndicator(color: BrandColors.ink)
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: showGradient
                          ? BrandColors.ink
                          : (isDark
                              ? const Color(0xFF6E6E73)
                              : const Color(0xFFA39C90)),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
