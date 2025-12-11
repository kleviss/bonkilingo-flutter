import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_helper.dart';
import '../../../core/constants/language_constants.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/cupertino_app_bar.dart';
import '../../widgets/cupertino_correction_card.dart';
import '../explanation/explanation_screen.dart';
import '../history/history_screen.dart';
import 'home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _textController = TextEditingController();
  String _inputText = '';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = ThemeHelper(themeMode);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoAppBar(title: 'Bonkilingo'),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Language Selection Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.backgroundTertiary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Auto-detect toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.translate,
                              size: 20,
                              color: theme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Target Language',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: theme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'Auto-detect',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CupertinoSwitch(
                              value: homeState.autoDetect,
                              onChanged: (value) {
                                ref
                                    .read(homeStateProvider.notifier)
                                    .toggleAutoDetect();
                              },
                              activeColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Language Picker
                    GestureDetector(
                      onTap: homeState.autoDetect && homeState.detectedLanguage != null
                          ? null
                          : () => _showLanguagePicker(context, theme),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.border,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getLanguageName(
                                homeState.detectedLanguage ??
                                    homeState.selectedLanguage,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.textPrimary,
                              ),
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

                    // Detection Status
                    if (homeState.autoDetect && homeState.isDetecting) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CupertinoActivityIndicator(
                              radius: 6,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Detecting language...',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (homeState.autoDetect && homeState.detectedLanguage != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Auto-detected: ${_getLanguageName(homeState.detectedLanguage!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Text Input
                    CupertinoTextField(
                      controller: _textController,
                      placeholder: 'Enter the text you want to correct...',
                      maxLines: 5,
                      padding: const EdgeInsets.all(12),
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 16,
                      ),
                      placeholderStyle: TextStyle(
                        color: theme.textTertiary,
                        fontSize: 16,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.border),
                      ),
                      onChanged: (text) {
                        setState(() {
                          _inputText = text;
                        });
                        ref
                            .read(homeStateProvider.notifier)
                            .onTextChanged(text);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Correct Button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: homeState.isLoading || _inputText.trim().isEmpty
                      ? null
                      : () {
                          ref
                              .read(homeStateProvider.notifier)
                              .correctText(_inputText);
                        },
                  child: homeState.isLoading
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.black,
                        )
                      : const Text(
                          'Correct Text',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Corrections Section
              const Text(
                'Corrections',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label, // Adapts to theme automatically!
                ),
              ),
              const SizedBox(height: 12),

              if (homeState.correctedText != null)
                CupertinoCorrectionCard(
                  correctedText: homeState.correctedText!,
                  inputText: _inputText,
                )
              else
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.border),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.description,
                        size: 48,
                        color: theme.textTertiary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No corrections yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap \'Correct Text\' to get started',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTertiary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => const HistoryScreen(),
                            ),
                          );
                        },
                        child: const Text('View correction history'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, ThemeHelper theme) {
    final homeNotifier = ref.read(homeStateProvider.notifier);
    final currentLanguage = ref.read(homeStateProvider).selectedLanguage;

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
                  homeNotifier.selectLanguage(
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
