import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class CorrectionCard extends StatefulWidget {
  final String correctedText;
  final String inputText;

  const CorrectionCard({
    super.key,
    required this.correctedText,
    required this.inputText,
  });

  @override
  State<CorrectionCard> createState() => _CorrectionCardState();
}

class _CorrectionCardState extends State<CorrectionCard> {
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.successLight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.correctedText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _copyToClipboard,
              icon: Icon(
                _isCopied ? Icons.check : Icons.copy,
                size: 18,
                color: AppColors.success,
              ),
              label: Text(
                _isCopied ? 'Copied!' : 'Copy Corrected Text',
                style: const TextStyle(color: AppColors.success),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.success),
                backgroundColor:
                    _isCopied ? AppColors.success.withOpacity(0.1) : null,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                // Navigate to explanation screen
                // TODO: Implement explanation navigation
              },
              icon: const Icon(
                Icons.help_outline,
                size: 18,
                color: AppColors.info,
              ),
              label: const Text(
                'Show Explanation',
                style: TextStyle(color: AppColors.info),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.info),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to history
                },
                child: const Text('View correction history'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

