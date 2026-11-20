import 'package:flutter/cupertino.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/utils/mistake_patterns.dart';

/// One of the learner's own corrections as a chip: the removed words struck
/// through on red, then the added words on green ("a → an").
class MistakeChangeText extends StatelessWidget {
  final WordChange change;
  final BrandPalette palette;

  const MistakeChangeText({
    required this.change,
    required this.palette,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final hint = TextStyle(color: p.muted, fontSize: 13);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.cardSunken,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text.rich(
        TextSpan(
          style: TextStyle(fontSize: 15, color: p.text),
          children: [
            if (change.removed.isNotEmpty)
              TextSpan(
                text: change.removed,
                style: TextStyle(
                  color: BrandPalette.red,
                  backgroundColor: p.redBg,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: BrandPalette.red,
                ),
              ),
            if (change.removed.isNotEmpty && change.added.isNotEmpty)
              TextSpan(text: '  →  ', style: TextStyle(color: p.muted)),
            if (change.added.isNotEmpty)
              TextSpan(
                text: change.added,
                style: TextStyle(
                  color: BrandPalette.green,
                  fontWeight: FontWeight.w700,
                  backgroundColor: p.greenBg,
                ),
              ),
            if (change.added.isEmpty) TextSpan(text: '  (remove)', style: hint),
            if (change.removed.isEmpty) TextSpan(text: '  (add)', style: hint),
          ],
        ),
      ),
    );
  }
}
