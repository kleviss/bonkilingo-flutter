import 'package:flutter/widgets.dart';

/// Fades scrolled content out at the top edge instead of cutting it off.
///
/// Brand screens sit under a transparent navigation bar over the glow, so a
/// scroll view would otherwise slice headings in half where it ends below the
/// bar. The fade grows with the scroll offset (up to [extent]), so content at
/// rest is never faded.
class FadeTopEdge extends StatefulWidget {
  final Widget child;
  final double extent;

  const FadeTopEdge({required this.child, this.extent = 28, super.key});

  @override
  State<FadeTopEdge> createState() => _FadeTopEdgeState();
}

class _FadeTopEdgeState extends State<FadeTopEdge> {
  double _fade = 0;

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final fade = notification.metrics.pixels.clamp(0.0, widget.extent);
    if (fade != _fade) setState(() => _fade = fade);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      // Always a ShaderMask (fully opaque at rest), so the scroll view below
      // keeps its state when the fade turns on.
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) {
          final stop =
              bounds.height > 0 ? (_fade / bounds.height).clamp(0.0, 1.0) : 0.0;
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              stop > 0 ? const Color(0x00000000) : const Color(0xFF000000),
              const Color(0xFF000000),
            ],
            stops: [0, stop],
          ).createShader(bounds);
        },
        child: widget.child,
      ),
    );
  }
}
