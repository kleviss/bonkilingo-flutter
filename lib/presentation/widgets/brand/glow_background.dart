import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import '../../../core/theme/brand_colors.dart';

/// Page background with soft, slowly drifting colour glows in the brand
/// colours. Drawn with radial gradients (no blur filter) so it stays cheap.
class GlowBackground extends StatefulWidget {
  final bool isDark;
  final Widget child;

  const GlowBackground({super.key, required this.isDark, required this.child});

  @override
  State<GlowBackground> createState() => _GlowBackgroundState();
}

class _GlowBackgroundState extends State<GlowBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 14),
  );

  @override
  void initState() {
    super.initState();
    // Respect "Reduce Motion": keep the glows still.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduceMotion =
          MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (!reduceMotion) _drift.repeat();
    });
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strength = widget.isDark ? 0.30 : 0.55;

    return ColoredBox(
      color: widget.isDark ? BrandColors.night : BrandColors.cream,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _drift,
              builder: (context, _) {
                final t = _drift.value * 2 * math.pi;
                return CustomPaint(
                  painter: _GlowPainter(
                    t: t,
                    glows: [
                      _Glow(BrandColors.sunny, const Offset(0.18, 0.16), 0.62,
                          strength),
                      _Glow(BrandColors.tangerine, const Offset(0.88, 0.26),
                          0.55, strength * 0.9),
                      _Glow(BrandColors.leaf, const Offset(0.10, 0.62), 0.45,
                          strength * 0.55),
                      _Glow(BrandColors.ribbon, const Offset(0.95, 0.70), 0.38,
                          strength * 0.35),
                    ],
                  ),
                );
              },
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _Glow {
  final Color color;
  final Offset center; // fraction of the page size
  final double radius; // fraction of the page width
  final double opacity;
  const _Glow(this.color, this.center, this.radius, this.opacity);
}

class _GlowPainter extends CustomPainter {
  final double t;
  final List<_Glow> glows;
  _GlowPainter({required this.t, required this.glows});

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < glows.length; i++) {
      final g = glows[i];
      // Each glow drifts on its own small ellipse, out of phase.
      final phase = t + i * 1.7;
      final center = Offset(
        size.width * (g.center.dx + 0.05 * math.cos(phase)),
        size.height * (g.center.dy + 0.03 * math.sin(phase * 1.3)),
      );
      final radius = size.width * g.radius;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            g.color.withValues(alpha: g.opacity),
            g.color.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.t != t;
}
