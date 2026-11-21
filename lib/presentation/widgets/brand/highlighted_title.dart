import 'package:flutter/cupertino.dart';
import '../../../core/theme/brand_colors.dart';

/// A headline where one word is swept with a yellow highlighter, like a
/// marked-up correction. Write the accent word between asterisks:
/// `'Write it. *Fix* it.'`. The marker draws in when [animate] turns true.
class HighlightedTitle extends StatelessWidget {
  final String text;
  final TextStyle style;
  final bool animate;
  final TextAlign textAlign;

  const HighlightedTitle(
    this.text, {
    super.key,
    required this.style,
    this.animate = true,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final parts = text.split('*');
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (parts[i].isEmpty) continue;
      if (i.isOdd) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: _MarkedWord(parts[i], style: style, animate: animate),
        ));
      } else {
        spans.add(TextSpan(text: parts[i]));
      }
    }
    return Text.rich(
      TextSpan(style: style, children: spans),
      textAlign: textAlign,
    );
  }
}

class _MarkedWord extends StatelessWidget {
  final String word;
  final TextStyle style;
  final bool animate;

  const _MarkedWord(this.word, {required this.style, required this.animate});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: animate ? 1 : 0),
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => CustomPaint(
        painter: _MarkerPainter(progress),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          // Turns ink as the marker covers it: ink on yellow reads in both
          // light and dark mode, while the bare word keeps the page colour.
          child: Text(
            word,
            style: style.copyWith(
              color: Color.lerp(style.color, BrandColors.ink, progress),
            ),
          ),
        ),
      ),
    );
  }
}

class _MarkerPainter extends CustomPainter {
  final double progress;
  _MarkerPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    // A slightly tilted stroke covering the whole word (ascenders included,
    // so no ink letter-tops show on a dark page), swept left to right.
    final top = size.height * 0.04;
    final bottom = size.height * 0.98;
    final right = size.width * progress;
    final path = Path()
      ..moveTo(0, top + 3)
      ..lineTo(right, top)
      ..lineTo(right - 2, bottom - 2)
      ..lineTo(2, bottom)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = BrandColors.sunny
        ..style = PaintingStyle.fill
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_MarkerPainter old) => old.progress != progress;
}
