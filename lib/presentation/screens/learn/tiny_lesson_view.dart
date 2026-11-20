import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/constants/language_constants.dart';
import '../../widgets/brand/brand_page.dart';
import '../../widgets/brand/brand_surfaces.dart';
import '../../widgets/brand/highlighted_title.dart';
import '../../widgets/brand/pill_button.dart';
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
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final p = BrandPalette(isDark);

    return BrandPage(
      isDark: isDark,
      onBack: () {
        ref.read(learnStateProvider.notifier).clearActiveTool();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HighlightedTitle(
              '*Tiny* lesson',
              textAlign: TextAlign.left,
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
              'Find relevant vocabulary, phrases and grammar tips for any '
              'situation.',
              style: TextStyle(fontSize: 16, height: 1.35, color: p.muted),
            ),
            const SizedBox(height: 24),

            // Situation input
            _FieldLabel('Describe a situation or topic', palette: p),
            _SituationField(
              palette: p,
              placeholder:
                  'e.g. ordering food at a restaurant, asking for directions…',
              onChanged: (value) {
                ref
                    .read(learnStateProvider.notifier)
                    .updateSituationInput(value);
              },
            ),

            const SizedBox(height: 18),

            // Language selection
            _FieldLabel('Language', palette: p),
            Semantics(
              button: true,
              label: 'Language, '
                  '${_getLanguageName(learnState.selectedLanguage)}',
              excludeSemantics: true,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: () => _showLanguagePicker(context, p),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: p.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.translate, size: 20, color: p.muted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getLanguageName(learnState.selectedLanguage),
                          style: TextStyle(fontSize: 17, color: p.text),
                        ),
                      ),
                      Icon(Icons.unfold_more, size: 20, color: p.muted),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Generate button
            PillButton(
              label: 'Generate tiny lesson',
              loading: learnState.isLoading,
              onPressed: learnState.isLoading ||
                      learnState.situationInput.trim().isEmpty
                  ? null
                  : () {
                      ref.read(learnStateProvider.notifier).generateLesson();
                    },
            ),

            // Generated lesson
            if (learnState.generatedLesson != null) ...[
              const SizedBox(height: 32),
              BrandSectionTitle('Your lesson', palette: p),
              BrandCard(
                palette: p,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MarkdownBody(
                      data: learnState.generatedLesson!,
                      styleSheet: _markdownStyle(p),
                    ),
                    const SizedBox(height: 18),
                    SecondaryPillButton(
                      palette: p,
                      icon: Icons.bookmark,
                      label: 'Save to my cheatsheet',
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
                    ),
                  ],
                ),
              ),
            ],

            if (learnState.error != null) ...[
              const SizedBox(height: 16),
              BrandCard(
                palette: p,
                color: p.redBg,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 20,
                      color: BrandPalette.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        learnState.error!,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          color: p.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, BrandPalette p) {
    final learnNotifier = ref.read(learnStateProvider.notifier);
    final currentLanguage = ref.read(learnStateProvider).selectedLanguage;
    final sheetColor = p.isDark ? p.card : BrandColors.cream;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 280,
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: p.muted.withValues(alpha: 0.25),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16, color: p.muted),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'Select language',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.text,
                    ),
                  ),
                  CupertinoButton(
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: BrandColors.tangerine,
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                backgroundColor: sheetColor,
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
                children: [
                  for (final lang in LanguageConstants.supportedLanguages)
                    Center(
                      child: Text(
                        lang.name,
                        style: TextStyle(fontSize: 18, color: p.text),
                      ),
                    ),
                ],
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

/// Small label above a field, as on the auth screens.
class _FieldLabel extends StatelessWidget {
  final String text;
  final BrandPalette palette;

  const _FieldLabel(this.text, {required this.palette});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: palette.text,
        ),
      ),
    );
  }
}

/// Multi-line prompt as a soft card with a tangerine ring while focused.
class _SituationField extends StatefulWidget {
  final BrandPalette palette;
  final String placeholder;
  final ValueChanged<String> onChanged;

  const _SituationField({
    required this.palette,
    required this.placeholder,
    required this.onChanged,
  });

  @override
  State<_SituationField> createState() => _SituationFieldState();
}

class _SituationFieldState extends State<_SituationField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              _focus.hasFocus ? BrandColors.tangerine : const Color(0x00000000),
          width: 1.5,
        ),
        boxShadow: p.cardShadow,
      ),
      child: CupertinoTextField(
        focusNode: _focus,
        placeholder: widget.placeholder,
        maxLines: 4,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: null,
        cursorColor: BrandColors.tangerine,
        style: TextStyle(fontSize: 17, height: 1.35, color: p.text),
        placeholderStyle: TextStyle(fontSize: 17, height: 1.35, color: p.muted),
        onChanged: widget.onChanged,
      ),
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
