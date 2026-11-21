import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../widgets/brand/brand_page.dart';
import '../../widgets/brand/brand_surfaces.dart';
import '../../widgets/brand/highlighted_title.dart';
import '../../widgets/brand/pill_button.dart';
import 'learn_provider.dart';
import '../../providers/theme_provider.dart';

class FlashcardsView extends ConsumerStatefulWidget {
  const FlashcardsView({super.key});

  @override
  ConsumerState<FlashcardsView> createState() => _FlashcardsViewState();
}

class _FlashcardsViewState extends ConsumerState<FlashcardsView> {
  String? _expandedLessonId;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final learnState = ref.watch(learnStateProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final p = BrandPalette(isDark);

    // Auto-expand lesson if specified (only once)
    if (!_hasInitialized && learnState.lessonToExpand != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _expandedLessonId = learnState.lessonToExpand;
            _hasInitialized = true;
          });
          // Clear the flag after expanding
          ref.read(learnStateProvider.notifier).clearLessonToExpand();
        }
      });
    }

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
              'My *cheatsheet*',
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
              'Your saved lessons and vocabulary',
              style: TextStyle(fontSize: 16, color: p.muted),
            ),
            const SizedBox(height: 20),
            if (learnState.savedLessons.isEmpty)
              BrandCard(
                palette: p,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                child: Column(
                  children: [
                    BrandIconBadge(
                      icon: Icons.bookmark_outline,
                      color: BrandColors.leaf,
                      isDark: isDark,
                      size: 64,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No saved lessons yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: p.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a tiny lesson to get started.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: p.muted),
                    ),
                    const SizedBox(height: 18),
                    PillButton(
                      label: 'Create lesson',
                      onPressed: () {
                        ref
                            .read(learnStateProvider.notifier)
                            .setActiveTool(LearnTool.tinyLesson);
                      },
                    ),
                  ],
                ),
              )
            else
              Column(
                children: learnState.savedLessons.map((lesson) {
                  final isExpanded = _expandedLessonId == lesson.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LessonCard(
                      palette: p,
                      title: lesson.title,
                      savedOn: lesson.createdAt?.formattedDate,
                      content: lesson.content,
                      isExpanded: isExpanded,
                      onDelete: () => _showDeleteDialog(context, lesson.id),
                      onToggle: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedLessonId = null;
                          } else {
                            _expandedLessonId = lesson.id;
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String lessonId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete lesson'),
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

/// A saved lesson as a large card: the title face, and the lesson itself on
/// a sunken panel when expanded.
class _LessonCard extends StatelessWidget {
  final BrandPalette palette;
  final String title;
  final String? savedOn;
  final String content;
  final bool isExpanded;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const _LessonCard({
    required this.palette,
    required this.title,
    required this.savedOn,
    required this.content,
    required this.isExpanded,
    required this.onDelete,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final p = palette;
    return BrandCard(
      palette: p,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              BrandIconBadge(
                icon: Icons.bookmark,
                color: BrandColors.leaf,
                isDark: p.isDark,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                      ),
                    ),
                    if (savedOn != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Saved on $savedOn',
                        style: TextStyle(fontSize: 13, color: p.muted),
                      ),
                    ],
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                onPressed: onDelete,
                child: Semantics(
                  label: 'Delete lesson',
                  child: const Icon(
                    Icons.delete_outline,
                    size: 22,
                    color: BrandPalette.red,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                onPressed: onToggle,
                child: Semantics(
                  label: isExpanded ? 'Hide lesson' : 'Show lesson',
                  child: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 26,
                    color: p.text,
                  ),
                ),
              ),
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: BoxDecoration(
                  color: p.cardSunken,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: MarkdownBody(
                  data: content,
                  styleSheet: _markdownStyle(p),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Markdown text in the brand colours, sized for a card panel.
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
    code: text.copyWith(fontWeight: FontWeight.w600, backgroundColor: p.card),
    h1: heading.copyWith(fontSize: 22),
    h2: heading.copyWith(fontSize: 19),
    h3: heading.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
    h4: heading.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
    h5: heading.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
    h6: heading.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
    blockquote: text.copyWith(color: p.muted),
    blockquoteDecoration: BoxDecoration(
      color: p.card,
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
