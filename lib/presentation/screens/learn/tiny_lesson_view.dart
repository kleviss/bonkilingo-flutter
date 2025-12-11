import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_helper.dart';
import '../../../core/constants/language_constants.dart';
import 'learn_provider.dart';
import '../../providers/theme_provider.dart';

class TinyLessonView extends ConsumerStatefulWidget {
  const TinyLessonView({super.key});

  @override
  ConsumerState<TinyLessonView> createState() => _TinyLessonViewState();
}

class _TinyLessonViewState extends ConsumerState<TinyLessonView> {
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
        middle: const Text('Tiny Lesson'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tiny Lesson',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find relevant vocabulary, phrases, and grammar tips for any situation.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Situation Input
              const Text(
                'Describe a situation or topic',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                placeholder:
                    'e.g., Ordering food at a restaurant, asking for directions...',
                maxLines: 4,
                padding: const EdgeInsets.all(12),
                style: TextStyle(color: theme.textPrimary, fontSize: 16),
                placeholderStyle:
                    TextStyle(color: theme.textTertiary, fontSize: 16),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.border),
                ),
                onChanged: (value) {
                  ref.read(learnStateProvider.notifier).updateSituationInput(value);
                },
              ),

              const SizedBox(height: 16),

              // Language Selection
              const Text(
                'Language',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showLanguagePicker(context, theme),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getLanguageName(learnState.selectedLanguage),
                        style: TextStyle(fontSize: 16, color: theme.textPrimary),
                      ),
                      Icon(
                        Icons.unfold_more,
                        size: 16,
                        color: theme.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Generate Button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: learnState.isLoading ||
                          learnState.situationInput.trim().isEmpty
                      ? null
                      : () {
                          ref.read(learnStateProvider.notifier).generateLesson();
                        },
                  child: learnState.isLoading
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.black,
                        )
                      : const Text('Generate Tiny Lesson'),
                ),
              ),

              // Generated Lesson
              if (learnState.generatedLesson != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MarkdownBody(
                        data: learnState.generatedLesson!,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(fontSize: 14, height: 1.5),
                          h1: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          h2: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          h3: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton(
                        color: AppColors.info,
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () {
                          ref.read(learnStateProvider.notifier).saveLesson();
                          showCupertinoDialog(
                            context: context,
                            builder: (context) => CupertinoAlertDialog(
                              title: const Text('Success!'),
                              content: const Text(
                                'Lesson saved to your cheatsheet!',
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  isDefaultAction: true,
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bookmark,
                              size: 18,
                              color: CupertinoColors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Save to My Cheatsheet',
                              style: TextStyle(color: CupertinoColors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (learnState.error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    learnState.error!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, ThemeHelper theme) {
    final learnNotifier = ref.read(learnStateProvider.notifier);
    final currentLanguage = ref.read(learnStateProvider).selectedLanguage;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.border, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: theme.primary),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'Select Language',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                  CupertinoButton(
                    child: Text(
                      'Done',
                      style: TextStyle(color: theme.primary),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                backgroundColor: theme.cardBackground,
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: LanguageConstants.supportedLanguages.indexWhere(
                    (lang) => lang.code == currentLanguage,
                  ),
                ),
                onSelectedItemChanged: (index) {
                  learnNotifier.updateLanguage(
                    LanguageConstants.supportedLanguages[index].code,
                  );
                },
                children: LanguageConstants.supportedLanguages
                    .map((lang) => Center(
                      child: Text(
                        lang.name,
                        style: TextStyle(color: theme.textPrimary),
                      ),
                    ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    return LanguageConstants.supportedLanguages
            .firstWhere(
              (lang) => lang.code == code,
              orElse: () => const Language(code: '', name: 'Unknown'),
            )
            .name;
  }
}
