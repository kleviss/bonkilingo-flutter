import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_helper.dart';
import '../providers/theme_provider.dart';
import '../screens/explanation/explanation_screen.dart';
import '../screens/history/history_screen.dart';

class CupertinoCorrectionCard extends ConsumerStatefulWidget {
  final String correctedText;
  final String inputText;

  const CupertinoCorrectionCard({
    super.key,
    required this.correctedText,
    required this.inputText,
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
    setState(() {
      _isCopied = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });

    // Show iOS-style notification
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 50),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: CupertinoColors.white,
                size: 48,
              ),
              SizedBox(height: 12),
              Text(
                'Copied to clipboard!',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Auto dismiss after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = ThemeHelper(themeMode);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.successLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.success.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.correctedText,
            style: TextStyle(
              fontSize: 15,
              color: theme.textPrimary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Copy Button
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: AppColors.success,
            borderRadius: BorderRadius.circular(8),
            onPressed: _copyToClipboard,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isCopied ? Icons.check : Icons.content_copy,
                  size: 18,
                  color: CupertinoColors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _isCopied ? 'Copied!' : 'Copy Corrected Text',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Explanation Button
          CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: AppColors.info,
            borderRadius: BorderRadius.circular(8),
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
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 18,
                  color: CupertinoColors.white,
                ),
                SizedBox(width: 8),
                Text(
                  'Show Explanation',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // History Link
          Center(
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              },
              child: const Text(
                'View correction history',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

