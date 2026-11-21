import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/utils/word_diff.dart';
import '../../../data/models/chat_session_model.dart';
import '../../providers/chat_history_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/brand/brand_page.dart';
import '../../widgets/brand/brand_surfaces.dart';

const _blue = Color(0xFF4F8EF7);

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatHistory = ref.watch(chatHistoryProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final p = BrandPalette(isDark);

    return BrandPage(
      isDark: isDark,
      title: 'Correction history',
      child: chatHistory.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return _MessageState(
              palette: p,
              icon: Icons.history,
              color: BrandColors.tangerine,
              title: 'No corrections yet',
              message: 'Start correcting text to see your history here',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            itemCount: sessions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _HistoryEntry(session: sessions[index], palette: p),
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (error, stack) => _MessageState(
          palette: p,
          icon: Icons.warning_amber_rounded,
          color: BrandPalette.red,
          title: 'Error loading history',
          message: error.toString(),
        ),
      ),
    );
  }
}

/// One saved correction: language, source and time on top, then the
/// original with removed words struck out in red and the corrected text
/// with added words in green.
class _HistoryEntry extends StatelessWidget {
  final ChatSessionModel session;
  final BrandPalette palette;

  const _HistoryEntry({required this.session, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final parts =
        wordDiff(session.inputText.trim(), session.correctedText.trim());
    final textStyle = TextStyle(fontSize: 16, height: 1.45, color: p.text);

    return BrandCard(
      palette: p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Language as a small pill so it never wraps beside the
              // Keyboard tag (a Flexible next to a Spacer only got half the row).
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.cardSunken,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.translate, size: 13, color: p.muted),
                    const SizedBox(width: 4),
                    Text(
                      session.language.capitalize(),
                      semanticsLabel:
                          'Language: ${session.language.capitalize()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (session.source == ChatSessionModel.sourceKeyboard) ...[
                const SizedBox(width: 8),
                _KeyboardTag(palette: p),
              ],
              const Spacer(),
              if (session.createdAt != null)
                Text(
                  session.createdAt!.relativeTime,
                  style: TextStyle(fontSize: 12, color: p.muted),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _Label('Original', palette: p),
          const SizedBox(height: 4),
          Text.rich(
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
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: BoxDecoration(
              color: p.cardSunken,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('Corrected', palette: p, color: BrandPalette.green),
                const SizedBox(height: 4),
                Text.rich(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  final BrandPalette palette;
  final Color? color;

  const _Label(this.text, {required this.palette, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color ?? palette.muted,
      ),
    );
  }
}

/// Centred badge, title and one line: the empty and error states.
class _MessageState extends StatelessWidget {
  final BrandPalette palette;
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _MessageState({
    required this.palette,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandIconBadge(
              icon: icon,
              color: color,
              isDark: palette.isDark,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: palette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marks corrections made with the Bonkilingo keyboard.
class _KeyboardTag extends StatelessWidget {
  final BrandPalette palette;

  const _KeyboardTag({required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _blue.withValues(alpha: palette.isDark ? 0.22 : 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.keyboard, size: 12, color: _blue),
          SizedBox(width: 4),
          Text(
            'Keyboard',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _blue,
            ),
          ),
        ],
      ),
    );
  }
}
