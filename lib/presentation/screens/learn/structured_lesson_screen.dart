import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/brand_colors.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/brand/brand_page.dart';
import '../../widgets/brand/brand_surfaces.dart';
import '../../widgets/brand/highlighted_title.dart';
import '../../widgets/brand/pill_button.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../../data/models/lesson_progress_model.dart';
import '../../providers/providers.dart';

class StructuredLessonScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final String lessonTitle;
  final String lessonDescription;
  final List<LessonContent> content;

  const StructuredLessonScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonDescription,
    required this.content,
  });

  @override
  ConsumerState<StructuredLessonScreen> createState() =>
      _StructuredLessonScreenState();
}

class _StructuredLessonScreenState
    extends ConsumerState<StructuredLessonScreen> {
  int _currentSectionIndex = 0;
  bool _isCompleted = false;
  LessonProgressModel? _progress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserProvider).value?.id ?? '';
      final progressRepo = ref.read(lessonProgressRepositoryProvider);
      _progress = progressRepo.getProgress(userId, widget.lessonId);

      if (_progress != null && _progress!.completed) {
        _isCompleted = true;
        _currentSectionIndex = widget.content.length;
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeLesson() async {
    final userId = ref.read(currentUserProvider).value?.id ?? '';
    final progressRepo = ref.read(lessonProgressRepositoryProvider);
    final rewardsNotifier = ref.read(rewardsStateProvider.notifier);

    final progress = _progress ??
        progressRepo.createProgress(
          userId: userId,
          lessonId: widget.lessonId,
          lessonType: LessonType.structuredLesson,
        );

    final completedProgress = progress.copyWith(
      score: widget.content.length,
      totalQuestions: widget.content.length,
      correctAnswers: widget.content.length,
      completed: true,
      completedAt: DateTime.now(),
    );

    await progressRepo.saveProgress(completedProgress);
    await rewardsNotifier.earnLessonCompleteReward(widget.lessonId);

    setState(() {
      _isCompleted = true;
    });

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Lesson complete!'),
        content: const Text('Congratulations! You\'ve completed this lesson.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _nextSection() {
    if (_currentSectionIndex < widget.content.length - 1) {
      setState(() {
        _currentSectionIndex++;
      });
    } else {
      _completeLesson();
    }
  }

  void _previousSection() {
    if (_currentSectionIndex > 0) {
      setState(() {
        _currentSectionIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final p = BrandPalette(isDark);

    if (_isLoading) {
      return BrandPage(
        isDark: isDark,
        title: widget.lessonTitle,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Align(
            alignment: Alignment.topCenter,
            child: BrandCard(
              palette: p,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  const CupertinoActivityIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    'Loading your lesson…',
                    style: TextStyle(fontSize: 15, color: p.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return BrandPage(
      isDark: isDark,
      title: widget.lessonTitle,
      child: _isCompleted ? _buildCompletionView(p) : _buildLessonView(p),
    );
  }

  Widget _buildLessonView(BrandPalette p) {
    final section = widget.content[_currentSectionIndex];
    final progress = (_currentSectionIndex + 1) / widget.content.length;

    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  label: 'Section ${_currentSectionIndex + 1} of '
                      '${widget.content.length}',
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: p.cardSunken,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: BrandColors.iconGradient,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ExcludeSemantics(
                child: Text(
                  '${_currentSectionIndex + 1}/${widget.content.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.muted,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section title
                Semantics(
                  header: true,
                  child: Text(
                    section.title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      height: 1.15,
                      color: p.text,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (section.vocabulary.isNotEmpty) ...[
                  BrandSectionTitle('Vocabulary', palette: p),
                  BrandCard(
                    palette: p,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            BrandIconBadge(
                              icon: Icons.translate,
                              color: _blue,
                              isDark: p.isDark,
                              size: 32,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${section.vocabulary.length} words',
                              style: TextStyle(fontSize: 14, color: p.muted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final word in section.vocabulary)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: p.cardSunken,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  word,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: p.text,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                if (section.phrases.isNotEmpty) ...[
                  BrandSectionTitle('Phrases', palette: p),
                  _GroupedList(
                    palette: p,
                    icon: Icons.chat_bubble_outline,
                    color: _purple,
                    items: section.phrases,
                  ),
                  const SizedBox(height: 28),
                ],

                if (section.grammarTips.isNotEmpty) ...[
                  BrandSectionTitle('Grammar tips', palette: p),
                  _GroupedList(
                    palette: p,
                    icon: Icons.lightbulb_outline,
                    color: BrandColors.leaf,
                    items: section.grammarTips,
                  ),
                ],
              ],
            ),
          ),
        ),

        // Navigation buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              if (_currentSectionIndex > 0)
                Expanded(
                  child: SecondaryPillButton(
                    palette: p,
                    height: 56,
                    label: 'Previous',
                    onPressed: _previousSection,
                  ),
                ),
              if (_currentSectionIndex > 0) const SizedBox(width: 12),
              Expanded(
                child: PillButton(
                  label: _currentSectionIndex == widget.content.length - 1
                      ? 'Complete'
                      : 'Next',
                  onPressed: _nextSection,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionView(BrandPalette p) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: BrandIconBadge(
                icon: Icons.check_circle,
                color: BrandPalette.green,
                isDark: p.isDark,
                size: 96,
              ),
            ),
            const SizedBox(height: 24),
            HighlightedTitle(
              'Lesson *complete*',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                height: 1.15,
                color: p.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.lessonTitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: p.muted),
            ),
            const SizedBox(height: 32),
            PillButton(
              label: 'Done',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

const _blue = Color(0xFF4F8EF7);
const _purple = Color(0xFFB07CF5);

/// Lines of a lesson section as rows of a grouped card, each with the
/// section's colour-coded badge.
class _GroupedList extends StatelessWidget {
  final BrandPalette palette;
  final IconData icon;
  final Color color;
  final List<String> items;

  const _GroupedList({
    required this.palette,
    required this.icon,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      palette: palette,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) BrandRowDivider(palette: palette),
            BrandListRow(
              palette: palette,
              leading: BrandIconBadge(
                icon: icon,
                color: color,
                isDark: palette.isDark,
              ),
              title: item,
            ),
          ],
        ],
      ),
    );
  }
}

class LessonContent {
  final String title;
  final List<String> vocabulary;
  final List<String> phrases;
  final List<String> grammarTips;

  LessonContent({
    required this.title,
    this.vocabulary = const [],
    this.phrases = const [],
    this.grammarTips = const [],
  });
}
