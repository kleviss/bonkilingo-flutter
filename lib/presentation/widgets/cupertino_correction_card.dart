import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/utils/word_diff.dart';
import '../providers/theme_provider.dart';
import '../screens/explanation/explanation_screen.dart';

/// A correction shown as two cards: your text with the removed words struck
/// out in red, then the corrected text with the new words in green.
/// With [example] set, it's a static preview with no actions.
class CupertinoCorrectionCard extends ConsumerStatefulWidget {
  final String correctedText;
  final String inputText;
  final bool example;

  const CupertinoCorrectionCard({
    super.key,
    required this.correctedText,
    required this.inputText,
    this.example = false,
  });

  @override
  ConsumerState<CupertinoCorrectionCard> createState() =>
      _CupertinoCorrectionCardState();
}

class _CupertinoCorrectionCardState
    extends ConsumerState<CupertinoCorrectionCard> {
  bool _isCopied = false;

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.correctedText));
    HapticFeedback.lightImpact();
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final p = BrandPalette(isDark);
    final parts =
        wordDiff(widget.inputText.trim(), widget.correctedText.trim());
    final unchanged = parts.every((part) => part.op == DiffOp.same);
    final textStyle = TextStyle(fontSize: 17, height: 1.45, color: p.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!unchanged) ...[
          _Panel(
            palette: p,
            label: widget.example ? 'Example · your sentence' : 'Your sentence',
            child: Text.rich(
              TextSpan(
                style: textStyle,
                children: [
                  for (final part in parts)
                    if (part.op == DiffOp.same)
                      TextSpan(text: part.text)
                    else if (part.op == DiffOp.removed)
                      TextSpan(
                        text: part.text,
                        style: TextStyle(
                          color: BrandPalette.red,
                          backgroundColor: p.redBg,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: BrandPalette.red,
                          decorationThickness: 2,
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        _Panel(
          palette: p,
          label: unchanged ? 'Looks good, nothing to fix' : 'Corrected',
          labelIcon: unchanged ? Icons.check_circle : null,
          child: Text.rich(
            TextSpan(
              style: textStyle,
              children: [
                for (final part in parts)
                  if (part.op == DiffOp.same)
                    TextSpan(text: part.text)
                  else if (part.op == DiffOp.added)
                    TextSpan(
                      text: part.text,
                      style: TextStyle(
                        color: BrandPalette.green,
                        fontWeight: FontWeight.w600,
                        backgroundColor: p.greenBg,
                      ),
                    ),
              ],
            ),
          ),
        ),
        if (!widget.example) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionPill(
                  palette: p,
                  icon: _isCopied ? Icons.check : Icons.content_copy,
                  label: _isCopied ? 'Copied' : 'Copy',
                  onPressed: _copyToClipboard,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionPill(
                  palette: p,
                  icon: Icons.lightbulb_outline,
                  iconColor: BrandColors.tangerine,
                  label: 'Why?',
                  onPressed: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => ExplanationScreen(
                          correctedText: widget.correctedText,
                          inputText: widget.inputText,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final BrandPalette palette;
  final String label;
  final IconData? labelIcon;
  final Widget child;

  const _Panel({
    required this.palette,
    required this.label,
    required this.child,
    this.labelIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: palette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (labelIcon != null) ...[
                Icon(labelIcon, size: 14, color: BrandPalette.green),
                const SizedBox(width: 4),
              ],
              Text(label, style: TextStyle(fontSize: 12, color: palette.muted)),
            ],
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final BrandPalette palette;
  final IconData icon;
  final Color? iconColor;
  final String label;
  final VoidCallback onPressed;

  const _ActionPill({
    required this.palette,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(999),
          boxShadow: palette.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor ?? palette.text),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
