import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_helper.dart';
import '../../../core/utils/extensions.dart';
import 'learn_provider.dart';
import '../../providers/theme_provider.dart';

class FlashcardsView extends ConsumerStatefulWidget {
  const FlashcardsView({super.key});

  @override
  ConsumerState<FlashcardsView> createState() => _FlashcardsViewState();
}

class _FlashcardsViewState extends ConsumerState<FlashcardsView> {
  String? _expandedLessonId;

  @override
  void initState() {
    super.initState();
    // Auto-expand lesson if specified
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final learnState = ref.read(learnStateProvider);
      if (learnState.lessonToExpand != null) {
        setState(() {
          _expandedLessonId = learnState.lessonToExpand;
        });
        // Clear the flag after expanding
        ref.read(learnStateProvider.notifier).clearLessonToExpand();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final learnState = ref.watch(learnStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = ThemeHelper(themeMode);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            ref.read(learnStateProvider.notifier).clearActiveTool();
          },
        ),
        middle: const Text('My Cheatsheet'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'My Language Cheatsheet',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your saved lessons and vocabulary',
                style: TextStyle(
                  fontSize: 15,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              if (learnState.savedLessons.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.bookmark,
                        size: 64,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No saved lessons yet',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a Tiny Lesson to get started!',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton.filled(
                        onPressed: () {
                          ref
                              .read(learnStateProvider.notifier)
                              .setActiveTool(LearnTool.tinyLesson);
                        },
                        child: const Text('Create Lesson'),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: learnState.savedLessons.map((lesson) {
                    final isExpanded = _expandedLessonId == lesson.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.border),
                      ),
                      child: Column(
                        children: [
                          // Header
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lesson.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (lesson.createdAt != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Saved on ${lesson.createdAt!.formattedDate}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _showDeleteDialog(context, lesson.id),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                  ),
                                ),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setState(() {
                                      if (isExpanded) {
                                        _expandedLessonId = null;
                                      } else {
                                        _expandedLessonId = lesson.id;
                                      }
                                    });
                                  },
                                  child: Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Expanded Content
                          if (isExpanded) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.infoLight,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: MarkdownBody(
                                data: lesson.content,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(fontSize: 14, height: 1.5),
                                  h1: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  h2: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  h3: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String lessonId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Lesson'),
        content: const Text('Are you sure you want to delete this lesson?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              ref.read(learnStateProvider.notifier).deleteLesson(lessonId);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
