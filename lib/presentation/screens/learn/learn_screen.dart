import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_helper.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/cupertino_app_bar.dart';
import 'learn_provider.dart';
import 'tiny_lesson_view.dart';
import 'flashcards_view.dart';

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learnState = ref.watch(learnStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = ThemeHelper(themeMode);

    if (learnState.activeTool != null) {
      // Show tool-specific view
      return learnState.activeTool == LearnTool.tinyLesson
          ? const TinyLessonView()
          : const FlashcardsView();
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoAppBar(title: 'Learn'),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Learning Tools Section
              const Text(
                'Learning Tools',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label, // Adapts to theme!
                ),
              ),
              const SizedBox(height: 16),

              // Tiny Lesson Card
              _buildToolCard(
                context,
                ref,
                theme,
                icon: Icons.school,
                title: 'Tiny Lesson',
                description:
                    'Get vocabulary, phrases, and grammar tips for any situation.',
                color: theme.blueModule,
                onTap: () {
                  ref
                      .read(learnStateProvider.notifier)
                      .setActiveTool(LearnTool.tinyLesson);
                },
              ),

              const SizedBox(height: 12),

              // My Cheatsheet Card
              _buildToolCard(
                context,
                ref,
                theme,
                icon: Icons.bookmark,
                title: 'My Cheatsheet',
                description: 'Access your saved lessons and vocabulary flashcards.',
                color: theme.greenModule,
                onTap: () {
                  ref
                      .read(learnStateProvider.notifier)
                      .setActiveTool(LearnTool.flashcards);
                },
              ),

              const SizedBox(height: 32),

              // Personalized Learning Section
              const Text(
                'Personalized Learning',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 16),

              _buildLearningModuleCard(
                context,
                theme,
                icon: '📚',
                title: 'Vocabulary Quizzes',
                description: 'Practice words from your corrections',
                color: theme.orangeModule,
              ),
              const SizedBox(height: 12),
              _buildLearningModuleCard(
                context,
                theme,
                icon: '📝',
                title: 'Sentence Construction',
                description: 'Build sentences with corrected words',
                color: theme.blueModule,
              ),
              const SizedBox(height: 12),
              _buildLearningModuleCard(
                context,
                theme,
                icon: '🎯',
                title: 'Grammar Exercises',
                description: 'Improve grammar with your corrections',
                color: theme.greenModule,
              ),

              const SizedBox(height: 32),

              // Lessons Section
              const Text(
                'Lessons',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 16),

              _buildLearningModuleCard(
                context,
                theme,
                icon: '🌮',
                title: 'Beginner Spanish',
                description: 'Learn basic Spanish phrases and grammar',
                color: theme.yellowModule,
              ),
              const SizedBox(height: 12),
              _buildLearningModuleCard(
                context,
                theme,
                icon: '🗼',
                title: 'Intermediate French',
                description: 'Enhance your French with complex sentences',
                color: theme.purpleModule,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    WidgetRef ref,
    ThemeHelper theme, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon, 
                      size: 24,
                      color: theme.isDark ? CupertinoColors.white : AppColors.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.isDark ? CupertinoColors.white : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.isDark ? CupertinoColors.white.withOpacity(0.9) : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoButton.filled(
                onPressed: onTap,
                child: Text(
                  title == 'Tiny Lesson' ? 'Create Lesson' : 'View Cheatsheet',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningModuleCard(
    BuildContext context,
    ThemeHelper theme, {
    required String icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                icon,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                  minSize: 32,
                  onPressed: () {
                    // TODO: Implement start lesson
                  },
                  child: const Text(
                    'Start',
                    style: TextStyle(fontSize: 13),
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
