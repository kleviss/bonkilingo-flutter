import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/utils/mistake_patterns.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/brand/brand_surfaces.dart';
import '../../widgets/brand/glow_background.dart';
import '../../widgets/brand/highlighted_title.dart';
import '../../widgets/brand/pill_button.dart';
import '../../widgets/cupertino_app_bar.dart';
import 'learn_provider.dart';
import 'suggested_lesson_screen.dart';
import 'suggestions_provider.dart';
import 'tiny_lesson_view.dart';
import 'flashcards_view.dart';
import 'vocabulary_quiz_screen.dart';
import 'sentence_construction_screen.dart';
import 'grammar_exercise_screen.dart';
import 'structured_lesson_screen.dart'
    show StructuredLessonScreen, LessonContent;

const _blue = Color(0xFF4F8EF7);
const _purple = Color(0xFFB07CF5);

class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learnState = ref.watch(learnStateProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final p = BrandPalette(isDark);

    if (learnState.activeTool != null) {
      // Show tool-specific view
      return learnState.activeTool == LearnTool.tinyLesson
          ? const TinyLessonView()
          : const FlashcardsView();
    }

    void push(Widget screen) => Navigator.of(context).push(
          CupertinoPageRoute(builder: (context) => screen),
        );

    return GlowBackground(
      isDark: isDark,
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0x00000000),
        navigationBar: const CupertinoAppBar(title: 'Learn', transparent: true),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                HighlightedTitle(
                  'Learn from your *mistakes*',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1.15,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lessons and quizzes built from what you write.',
                  style: TextStyle(fontSize: 16, color: p.muted),
                ),
                const SizedBox(height: 20),

                // Suggested for you: lessons on what the learner keeps
                // getting corrected (in the app and with the keyboard).
                _SuggestedForYou(palette: p),
                const SizedBox(height: 32),

                // Learning tools
                BrandSectionTitle('Tools', palette: p),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ToolTile(
                        palette: p,
                        icon: Icons.bolt,
                        color: BrandColors.tangerine,
                        title: 'Tiny lesson',
                        description: 'Words and phrases for any situation',
                        onTap: () => ref
                            .read(learnStateProvider.notifier)
                            .setActiveTool(LearnTool.tinyLesson),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ToolTile(
                        palette: p,
                        icon: Icons.bookmark_outline,
                        color: BrandColors.leaf,
                        title: 'Cheatsheet',
                        description: 'Your saved lessons and flashcards',
                        onTap: () => ref
                            .read(learnStateProvider.notifier)
                            .setActiveTool(LearnTool.flashcards),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Practice from your corrections
                BrandSectionTitle('Practice your corrections', palette: p),
                BrandCard(
                  palette: p,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      BrandListRow(
                        palette: p,
                        leading: BrandIconBadge(
                          icon: Icons.quiz_outlined,
                          color: _blue,
                          isDark: isDark,
                        ),
                        title: 'Vocabulary quiz',
                        subtitle: 'Words from your corrections',
                        onTap: () => push(const VocabularyQuizScreen()),
                      ),
                      BrandRowDivider(palette: p),
                      BrandListRow(
                        palette: p,
                        leading: BrandIconBadge(
                          icon: Icons.view_agenda_outlined,
                          color: _purple,
                          isDark: isDark,
                        ),
                        title: 'Sentence building',
                        subtitle: 'Put corrected words in order',
                        onTap: () => push(const SentenceConstructionScreen()),
                      ),
                      BrandRowDivider(palette: p),
                      BrandListRow(
                        palette: p,
                        leading: BrandIconBadge(
                          icon: Icons.spellcheck,
                          color: BrandColors.leaf,
                          isDark: isDark,
                        ),
                        title: 'Grammar exercises',
                        subtitle: 'The rules behind your fixes',
                        onTap: () => push(const GrammarExerciseScreen()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Courses
                BrandSectionTitle('Courses', palette: p),
                BrandCard(
                  palette: p,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      BrandListRow(
                        palette: p,
                        leading: _LanguageBadge(
                          code: 'ES',
                          color: BrandColors.ribbon,
                          isDark: isDark,
                        ),
                        title: 'Beginner Spanish',
                        subtitle: 'Greetings, common phrases, questions',
                        onTap: () => push(_beginnerSpanish()),
                      ),
                      BrandRowDivider(palette: p),
                      BrandListRow(
                        palette: p,
                        leading: _LanguageBadge(
                          code: 'FR',
                          color: _blue,
                          isDark: isDark,
                        ),
                        title: 'Intermediate French',
                        subtitle: 'Past, future and conditional',
                        onTap: () => push(_intermediateFrench()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _beginnerSpanish() {
    return StructuredLessonScreen(
      lessonId: 'beginner_spanish',
      lessonTitle: 'Beginner Spanish',
      lessonDescription: 'Learn basic Spanish phrases and grammar',
      content: [
        LessonContent(
          title: 'Greetings',
          vocabulary: [
            'Hola',
            'Buenos días',
            'Buenas tardes',
            'Buenas noches',
          ],
          phrases: [
            'Hola, ¿cómo estás?',
            'Buenos días, señor',
            'Buenas noches',
          ],
          grammarTips: [
            'Use "Buenos días" before noon',
            'Use "Buenas tardes" in the afternoon',
          ],
        ),
        LessonContent(
          title: 'Common Phrases',
          vocabulary: [
            'Por favor',
            'Gracias',
            'De nada',
            'Perdón',
          ],
          phrases: [
            'Por favor, ayúdame',
            'Muchas gracias',
            'De nada, no hay problema',
          ],
          grammarTips: [
            '"Por favor" means "please"',
            '"De nada" is the response to "gracias"',
          ],
        ),
        LessonContent(
          title: 'Questions',
          vocabulary: [
            '¿Qué?',
            '¿Cómo?',
            '¿Dónde?',
            '¿Cuándo?',
          ],
          phrases: [
            '¿Qué es esto?',
            '¿Cómo estás?',
            '¿Dónde está el baño?',
          ],
          grammarTips: [
            'Questions in Spanish start with ¿',
            'Question words have accents',
          ],
        ),
      ],
    );
  }

  Widget _intermediateFrench() {
    return StructuredLessonScreen(
      lessonId: 'intermediate_french',
      lessonTitle: 'Intermediate French',
      lessonDescription: 'Enhance your French with complex sentences',
      content: [
        LessonContent(
          title: 'Past Tense',
          vocabulary: [
            'J\'ai fait',
            'Il est allé',
            'Nous avons vu',
            'Vous avez dit',
          ],
          phrases: [
            'J\'ai fait mes devoirs',
            'Il est allé au marché',
            'Nous avons vu un film',
          ],
          grammarTips: [
            'Use "avoir" for most verbs',
            'Some verbs use "être" instead',
          ],
        ),
        LessonContent(
          title: 'Future Tense',
          vocabulary: [
            'Je vais',
            'Tu vas',
            'Il va',
            'Nous allons',
          ],
          phrases: [
            'Je vais manger',
            'Tu vas partir',
            'Nous allons voyager',
          ],
          grammarTips: [
            'Future tense uses "aller" + infinitive',
            'This is called "futur proche"',
          ],
        ),
        LessonContent(
          title: 'Conditional',
          vocabulary: [
            'Je voudrais',
            'Il pourrait',
            'Nous devrions',
            'Vous aimeriez',
          ],
          phrases: [
            'Je voudrais un café',
            'Il pourrait venir',
            'Nous devrions partir',
          ],
          grammarTips: [
            'Conditional expresses politeness',
            'Also used for hypothetical situations',
          ],
        ),
      ],
    );
  }
}

/// Hero card for the top recurring mistake, with the next ones below.
class _SuggestedForYou extends ConsumerWidget {
  final BrandPalette palette;

  const _SuggestedForYou({required this.palette});

  void _open(BuildContext context, MistakePattern pattern) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => SuggestedLessonScreen(pattern: pattern),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = palette;
    final patterns = ref.watch(mistakePatternsProvider).valueOrNull;
    if (patterns == null) {
      return const SizedBox(
        height: 120,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (patterns.isEmpty) {
      return BrandCard(
        palette: p,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            BrandIconBadge(
              icon: Icons.auto_awesome,
              color: BrandColors.tangerine,
              isDark: p.isDark,
              size: 48,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suggestions show up here',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Correct a few messages in the app or with the keyboard. '
                    "We'll suggest lessons on what you keep getting wrong.",
                    style:
                        TextStyle(fontSize: 14, height: 1.35, color: p.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final top = patterns.first;
    final more = patterns.skip(1).take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BrandCard(
          palette: p,
          radius: 26,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: BrandColors.sunny
                      .withValues(alpha: p.isDark ? 0.18 : 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: BrandColors.tangerine,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Suggested for you',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                top.title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Corrected in ${top.corrections} of your recent messages',
                style: TextStyle(fontSize: 14, color: p.muted),
              ),
              if (top.examples.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final example in top.examples.take(3))
                      _ChangeChip(change: example, palette: p),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              PillButton(
                label: 'Start lesson',
                onPressed: () => _open(context, top),
              ),
            ],
          ),
        ),
        if (more.isNotEmpty) ...[
          const SizedBox(height: 10),
          BrandCard(
            palette: p,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final (i, pattern) in more.indexed) ...[
                  if (i > 0) BrandRowDivider(palette: p),
                  BrandListRow(
                    palette: p,
                    leading: BrandIconBadge(
                      icon: Icons.replay,
                      color: BrandColors.tangerine,
                      isDark: p.isDark,
                    ),
                    title: pattern.title,
                    subtitle: 'Corrected ${pattern.corrections} times',
                    onTap: () => _open(context, pattern),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// One of the learner's own fixes as a chip: "a" struck out → "an".
class _ChangeChip extends StatelessWidget {
  final WordChange change;
  final BrandPalette palette;

  const _ChangeChip({required this.change, required this.palette});

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.cardSunken,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text.rich(
        TextSpan(
          style: TextStyle(fontSize: 15, color: p.text),
          children: [
            if (change.removed.isNotEmpty)
              TextSpan(
                text: change.removed,
                style: TextStyle(
                  color: BrandPalette.red,
                  backgroundColor: p.redBg,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: BrandPalette.red,
                ),
              ),
            if (change.removed.isNotEmpty && change.added.isNotEmpty)
              TextSpan(text: '  →  ', style: TextStyle(color: p.muted)),
            if (change.added.isNotEmpty)
              TextSpan(
                text: change.added,
                style: TextStyle(
                  color: BrandPalette.green,
                  fontWeight: FontWeight.w700,
                  backgroundColor: p.greenBg,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Square tool tile tinted in its colour.
class _ToolTile extends StatelessWidget {
  final BrandPalette palette;
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ToolTile({
    required this.palette,
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return Semantics(
      button: true,
      label: '$title. $description',
      excludeSemantics: true,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 0,
        onPressed: onTap,
        child: Container(
          height: 156,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              color.withValues(alpha: p.isDark ? 0.16 : 0.18),
              p.card,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: p.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icon, size: 22, color: BrandColors.ink),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, height: 1.3, color: p.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Language code in a tinted rounded square, used for course rows.
class _LanguageBadge extends StatelessWidget {
  final String code;
  final Color color;
  final bool isDark;

  const _LanguageBadge({
    required this.code,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
