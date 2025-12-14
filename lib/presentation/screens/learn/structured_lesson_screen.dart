import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_helper.dart';
import '../../providers/theme_provider.dart';
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
        title: const Text('Lesson Complete!'),
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
    final themeMode = ref.watch(themeModeProvider);
    final theme = ThemeHelper(themeMode);

    if (_isLoading) {
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.lessonTitle),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.lessonTitle),
      ),
      child: SafeArea(
        child: _isCompleted
            ? _buildCompletionView(theme)
            : _buildLessonView(theme),
      ),
    );
  }

  Widget _buildLessonView(ThemeHelper theme) {
    final section = widget.content[_currentSectionIndex];
    final progress = (_currentSectionIndex + 1) / widget.content.length;

    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentSectionIndex + 1}/${widget.content.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section title
                Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Section content
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (section.vocabulary.isNotEmpty) ...[
                        Text(
                          'Vocabulary:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: section.vocabulary
                              .map((word) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: theme.primary.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      word,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (section.phrases.isNotEmpty) ...[
                        Text(
                          'Phrases:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...section.phrases.map((phrase) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.cardBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: theme.border),
                                ),
                                child: Text(
                                  phrase,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: theme.textPrimary,
                                  ),
                                ),
                              ),
                            )),
                        const SizedBox(height: 20),
                      ],
                      if (section.grammarTips.isNotEmpty) ...[
                        Text(
                          'Grammar Tips:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...section.grammarTips.map((tip) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.lightbulb_outline,
                                    size: 20,
                                    color: theme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tip,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: theme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Navigation buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_currentSectionIndex > 0)
                Expanded(
                  child: CupertinoButton(
                    onPressed: _previousSection,
                    color: theme.cardBackground,
                    child: const Text('Previous'),
                  ),
                ),
              if (_currentSectionIndex > 0) const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton.filled(
                  onPressed: _nextSection,
                  child: Text(
                    _currentSectionIndex == widget.content.length - 1
                        ? 'Complete'
                        : 'Next',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionView(ThemeHelper theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: CupertinoColors.systemGreen,
            ),
            const SizedBox(height: 24),
            Text(
              'Lesson Complete!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.lessonTitle,
              style: TextStyle(
                fontSize: 20,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            CupertinoButton.filled(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
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
