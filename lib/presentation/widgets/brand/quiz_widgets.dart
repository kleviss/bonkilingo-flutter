import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import '../../../core/theme/brand_colors.dart';
import 'brand_surfaces.dart';

/// Page body for a quiz step: scrolling content with the primary action
/// (and optional feedback above it) pinned to the bottom.
class QuizLayout extends StatelessWidget {
  final List<Widget> children;
  final Widget? feedback;
  final Widget action;

  const QuizLayout({
    super.key,
    required this.children,
    required this.action,
    this.feedback,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (feedback != null) ...[feedback!, const SizedBox(height: 12)],
              action,
            ],
          ),
        ),
      ],
    );
  }
}

/// Slim gradient progress bar with "Question 3 of 10" under it.
class QuizProgressBar extends StatelessWidget {
  final BrandPalette palette;

  /// 1-based number of the current question.
  final int current;
  final int total;

  const QuizProgressBar({
    super.key,
    required this.palette,
    required this.current,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = total == 0 ? 0.0 : (current / total).clamp(0.0, 1.0);
    return Semantics(
      label: 'Question $current of $total',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: palette.cardSunken,
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  gradient: BrandColors.iconGradient,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Question $current of $total',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: palette.muted,
            ),
          ),
        ],
      ),
    );
  }
}

/// The question card: a small muted source label, the prompt, then [child]
/// (usually a sunken box with the word or sentence).
class QuizQuestionCard extends StatelessWidget {
  final BrandPalette palette;
  final bool fromCorrections;
  final String prompt;
  final Widget? child;

  const QuizQuestionCard({
    super.key,
    required this.palette,
    required this.fromCorrections,
    required this.prompt,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      palette: palette,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                fromCorrections ? Icons.history : Icons.school_outlined,
                size: 14,
                color: BrandColors.tangerine,
              ),
              const SizedBox(width: 4),
              Text(
                fromCorrections
                    ? 'From your corrections'
                    : 'Practice questions',
                style: TextStyle(fontSize: 12, color: palette.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            prompt,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: palette.text,
            ),
          ),
          if (child != null) ...[const SizedBox(height: 14), child!],
        ],
      ),
    );
  }
}

/// Sunken box inside a question card.
class QuizSunkenBox extends StatelessWidget {
  final BrandPalette palette;
  final Widget child;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final AlignmentGeometry? alignment;

  const QuizSunkenBox({
    super.key,
    required this.palette,
    required this.child,
    this.borderColor,
    this.padding = const EdgeInsets.all(14),
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.cardSunken,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ?? const Color(0x00000000),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}

enum AnswerTileState { idle, selected, correct, wrong }

/// One answer option. Selected gets a tangerine border; after checking, the
/// right answer turns green and a wrong pick turns red.
class AnswerTile extends StatelessWidget {
  final BrandPalette palette;
  final String label;
  final AnswerTileState state;
  final VoidCallback? onTap;

  const AnswerTile({
    super.key,
    required this.palette,
    required this.label,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border) = switch (state) {
      AnswerTileState.idle => (palette.cardSunken, const Color(0x00000000)),
      AnswerTileState.selected => (palette.cardSunken, BrandColors.tangerine),
      AnswerTileState.correct => (palette.greenBg, BrandPalette.green),
      AnswerTileState.wrong => (palette.redBg, BrandPalette.red),
    };
    final icon = switch (state) {
      AnswerTileState.correct => Icons.check_circle,
      AnswerTileState.wrong => Icons.cancel,
      _ => null,
    };

    return Semantics(
      button: onTap != null,
      selected: state == AnswerTileState.selected,
      label: switch (state) {
        AnswerTileState.correct => '$label, correct answer',
        AnswerTileState.wrong => '$label, wrong',
        _ => label,
      },
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 6),
                Icon(icon, size: 18, color: border),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Lays answer tiles out in two equal-height columns.
class AnswerGrid extends StatelessWidget {
  final List<Widget> tiles;

  const AnswerGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: tiles[i]),
              const SizedBox(width: 10),
              Expanded(
                child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

/// Pill word chip for sentence building. In the pool it is a lifted card;
/// in the answer area it shows a small close icon to take it back out.
class WordChip extends StatelessWidget {
  final BrandPalette palette;
  final String word;
  final bool inAnswer;
  final VoidCallback? onTap;

  const WordChip({
    super.key,
    required this.palette,
    required this.word,
    this.inAnswer = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: inAnswer ? '$word, remove' : word,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: EdgeInsets.fromLTRB(16, 9, inAnswer ? 10 : 16, 9),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(999),
            boxShadow: inAnswer ? null : palette.cardShadow,
            border: palette.isDark && !inAnswer
                ? Border.all(color: palette.muted.withValues(alpha: 0.25))
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                word,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: palette.text,
                ),
              ),
              if (inAnswer && onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.close, size: 16, color: palette.muted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline result after checking an answer: green or red tinted, icon + line.
class QuizFeedbackCard extends StatelessWidget {
  final BrandPalette palette;
  final bool correct;
  final String message;

  const QuizFeedbackCard({
    super.key,
    required this.palette,
    required this.correct,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final color = correct ? BrandPalette.green : BrandPalette.red;
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: correct ? palette.greenBg : palette.redBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              correct ? Icons.check_circle : Icons.cancel,
              size: 22,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: palette.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big score in the sunny gradient card, like the rewards balance card.
class QuizResultCard extends StatelessWidget {
  final String title;
  final int score;
  final int total;

  const QuizResultCard({
    super.key,
    required this.title,
    required this.score,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    const inkSoft = Color(0xB31C1C1E);
    final percentage = total == 0 ? 0 : (score / total * 100).round();
    final passed = percentage >= 70;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
      decoration: BoxDecoration(
        gradient: BrandColors.iconGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: BrandColors.tangerine.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: inkSoft,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: BrandColors.ink.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  passed ? Icons.check_circle : Icons.sentiment_dissatisfied,
                  size: 20,
                  color: BrandColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Semantics(
            label: 'Score $score of $total',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$score',
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                    height: 1.05,
                    color: BrandColors.ink,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 6, bottom: 9),
                  child: Text(
                    '/ $total',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: BrandColors.ink.withValues(alpha: 0.12)),
          const SizedBox(height: 12),
          Text(
            '$percentage% correct',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: BrandColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty or not-enough-data state: a card with a badge, title and one line.
class QuizEmptyState extends StatelessWidget {
  final BrandPalette palette;
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const QuizEmptyState({
    super.key,
    required this.palette,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Align(
        alignment: Alignment.topCenter,
        child: BrandCard(
          palette: palette,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              BrandIconBadge(
                icon: icon,
                color: color,
                isDark: palette.isDark,
                size: 48,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: palette.muted,
                      ),
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
}
