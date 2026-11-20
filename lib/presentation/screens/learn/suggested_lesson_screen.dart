import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/utils/error_message_helper.dart';
import '../../../core/utils/mistake_patterns.dart';
import '../../providers/auth_provider.dart';
import '../../providers/providers.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/brand/brand_page.dart';
import '../../widgets/brand/brand_surfaces.dart';
import '../../widgets/brand/pill_button.dart';
import 'mistake_change_text.dart';

/// A short lesson and quiz on a mistake the learner keeps making, generated
/// from their own corrections.
class SuggestedLessonScreen extends ConsumerStatefulWidget {
  final MistakePattern pattern;

  const SuggestedLessonScreen({required this.pattern, super.key});

  @override
  ConsumerState<SuggestedLessonScreen> createState() =>
      _SuggestedLessonScreenState();
}

class _SuggestedLessonScreenState extends ConsumerState<SuggestedLessonScreen> {
  String? _lesson;
  String? _error;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _lesson = null;
      _error = null;
    });
    try {
      final lesson = await ref
          .read(lessonRepositoryProvider)
          .generateMistakeLesson(widget.pattern);
      if (mounted) setState(() => _lesson = lesson);
    } catch (e) {
      if (mounted) {
        setState(() => _error = ErrorMessageHelper.getUserFriendlyMessage(e));
      }
    }
  }

  Future<void> _save() async {
    final lesson = _lesson;
    if (lesson == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(lessonRepositoryProvider).saveLesson(
            userId: ref.read(currentUserProvider).value?.id ?? '',
            title: widget.pattern.title,
            content: lesson,
          );
      if (mounted) setState(() => _saved = true);
    } catch (e) {
      if (mounted) {
        setState(() => _error = ErrorMessageHelper.getUserFriendlyMessage(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final p = BrandPalette(isDark);
    final pattern = widget.pattern;

    return BrandPage(
      isDark: isDark,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            pattern.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.15,
              color: p.text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You were corrected on this in ${pattern.corrections} of your '
            'recent messages.',
            style: TextStyle(fontSize: 16, height: 1.35, color: p.muted),
          ),
          if (pattern.examples.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final example in pattern.examples)
                  MistakeChangeText(change: example, palette: p),
              ],
            ),
          ],
          const SizedBox(height: 28),
          BrandSectionTitle('Lesson', palette: p),
          _buildLesson(p),
          if (_lesson != null) ...[
            const SizedBox(height: 20),
            PillButton(
              label:
                  _saved ? 'Saved to my cheatsheet' : 'Save to my cheatsheet',
              loading: _saving,
              onPressed: _saved || _saving ? null : _save,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLesson(BrandPalette p) {
    final lesson = _lesson;
    if (_error != null && lesson == null) {
      return BrandCard(
        palette: p,
        color: p.redBg,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              size: 28,
              color: BrandPalette.red,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.35, color: p.text),
            ),
            const SizedBox(height: 14),
            SecondaryPillButton(
              palette: p,
              label: 'Try again',
              icon: Icons.refresh,
              onPressed: _generate,
            ),
          ],
        ),
      );
    }
    if (lesson == null) {
      return BrandCard(
        palette: p,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            const CupertinoActivityIndicator(),
            const SizedBox(height: 12),
            Text(
              'Writing a lesson from your corrections…',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: p.muted),
            ),
          ],
        ),
      );
    }
    return BrandCard(
      palette: p,
      padding: const EdgeInsets.all(20),
      child: MarkdownBody(data: lesson, styleSheet: _markdownStyle(p)),
    );
  }
}

/// Markdown text in the brand colours, sized for a [BrandCard].
MarkdownStyleSheet _markdownStyle(BrandPalette p) {
  final text = TextStyle(fontSize: 16, height: 1.5, color: p.text);
  final heading = text.copyWith(
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    height: 1.3,
  );
  return MarkdownStyleSheet(
    p: text,
    listBullet: text.copyWith(color: p.muted),
    strong: text.copyWith(fontWeight: FontWeight.w700),
    em: text.copyWith(fontStyle: FontStyle.italic),
    a: text.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: BrandColors.tangerine,
    ),
    code: text.copyWith(
      fontWeight: FontWeight.w600,
      backgroundColor: p.cardSunken,
    ),
    h1: heading.copyWith(fontSize: 22),
    h2: heading.copyWith(fontSize: 19),
    h3: heading.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
    h4: heading.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
    h5: heading.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
    h6: heading.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
    blockquote: text.copyWith(color: p.muted),
    blockquoteDecoration: BoxDecoration(
      color: p.cardSunken,
      borderRadius: BorderRadius.circular(12),
    ),
    tableHead: text.copyWith(fontWeight: FontWeight.w700),
    tableBody: text,
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: p.muted.withValues(alpha: 0.25), width: 0.5),
      ),
    ),
  );
}
