import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import '../../../core/theme/brand_colors.dart';
import '../../../core/utils/extensions.dart';

/// Small, self-playing mock-ups of real Bonkilingo screens for onboarding.
/// Each one plays from the start whenever its page becomes [active].

/// Shared driver: a controller that replays when the page becomes active.
abstract class _DemoState<T extends StatefulWidget> extends State<T>
    with SingleTickerProviderStateMixin {
  late final AnimationController c;
  Duration get duration;
  bool get active;

  @override
  void initState() {
    super.initState();
    c = AnimationController(vsync: this, duration: duration);
    if (active) WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  void _play() {
    if (!mounted) return;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      c.value = 1;
    } else {
      c.forward(from: 0);
    }
  }

  void onActiveChanged(bool wasActive) {
    if (active && !wasActive) _play();
  }

  /// 0→1 progress of the sub-step between [start] and [end] (fractions of
  /// the whole demo), eased.
  double step(double start, double end) {
    final v = ((c.value - start) / (end - start)).clamp(0.0, 1.0);
    return Curves.easeOutCubic.transform(v);
  }

  /// Fade + rise-in for a block that appears at [start].
  Widget reveal(double start, Widget child, {double end = -1}) {
    final p = step(start, end < 0 ? start + 0.12 : end);
    return Opacity(
      opacity: p,
      child: Transform.translate(offset: Offset(0, 14 * (1 - p)), child: child),
    );
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }
}

Widget _card(BrandPalette p, {required Widget child, EdgeInsets? padding}) {
  return Container(
    width: double.infinity,
    padding: padding ?? const EdgeInsets.fromLTRB(16, 12, 16, 14),
    decoration: BoxDecoration(
      color: p.card,
      borderRadius: BorderRadius.circular(20),
      boxShadow: p.isDark
          ? null
          : [
              BoxShadow(
                color: const Color(0xFF8A5A00).withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
    ),
    child: child,
  );
}

Widget _label(BrandPalette p, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text, style: TextStyle(fontSize: 12, color: p.muted)),
    );

Widget _bonkChip(String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: BrandColors.iconGradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 18, color: BrandColors.ink),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: BrandColors.ink,
            ),
          ),
        ],
      ),
    );

// ---------------------------------------------------------------------------
// 1. Correction: your sentence → corrected sentence → why → BONK earned.

class CorrectionDemo extends StatefulWidget {
  final bool active;
  final bool isDark;
  const CorrectionDemo({super.key, required this.active, required this.isDark});

  @override
  State<CorrectionDemo> createState() => _CorrectionDemoState();
}

class _CorrectionDemoState extends _DemoState<CorrectionDemo> {
  @override
  Duration get duration => const Duration(milliseconds: 3600);
  @override
  bool get active => widget.active;

  @override
  void didUpdateWidget(CorrectionDemo old) {
    super.didUpdateWidget(old);
    onActiveChanged(old.active);
  }

  @override
  Widget build(BuildContext context) {
    final p = BrandPalette(widget.isDark);
    final sentence = TextStyle(fontSize: 18, color: p.text, height: 1.4);

    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final mark = step(0.12, 0.26);
        final fix = step(0.40, 0.52);
        final pop = step(0.80, 0.92);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _card(
              p,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label(p, 'Your sentence'),
                  Text.rich(
                    TextSpan(style: sentence, children: [
                      const TextSpan(text: 'I '),
                      TextSpan(
                        text: 'goed',
                        style: TextStyle(
                          color: Color.lerp(p.text, BrandPalette.red, mark),
                          backgroundColor: Color.lerp(p.card, p.redBg, mark),
                          decoration: mark > 0.5
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: BrandPalette.red,
                          decorationThickness: 2,
                        ),
                      ),
                      const TextSpan(text: ' to the store yesterday.'),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            reveal(
              0.30,
              _card(
                p,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label(p, 'Corrected'),
                    Text.rich(
                      TextSpan(style: sentence, children: [
                        const TextSpan(text: 'I '),
                        TextSpan(
                          text: ' went ',
                          style: TextStyle(
                            color: Color.lerp(p.text, BrandPalette.green, fix),
                            fontWeight: FontWeight.w600,
                            backgroundColor: Color.lerp(p.card, p.greenBg, fix),
                          ),
                        ),
                        const TextSpan(text: ' to the store yesterday.'),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            reveal(
              0.58,
              _card(
                p,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: BrandColors.sunny.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lightbulb_outline,
                          size: 20, color: BrandColors.tangerine),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Why?',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: p.text)),
                          Text('"Go" is irregular. Its past tense is "went".',
                              style: TextStyle(fontSize: 13, color: p.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Opacity(
              opacity: pop,
              child: Transform.scale(
                scale: 0.6 + 0.4 * Curves.elasticOut.transform(pop),
                child: _bonkChip('+250 BONK'),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Keyboard: fix a message in another app with the Bonkilingo keyboard.

class KeyboardDemo extends StatefulWidget {
  final bool active;
  final bool isDark;
  const KeyboardDemo({super.key, required this.active, required this.isDark});

  @override
  State<KeyboardDemo> createState() => _KeyboardDemoState();
}

class _KeyboardDemoState extends _DemoState<KeyboardDemo> {
  @override
  Duration get duration => const Duration(milliseconds: 3200);
  @override
  bool get active => widget.active;

  @override
  void didUpdateWidget(KeyboardDemo old) {
    super.didUpdateWidget(old);
    onActiveChanged(old.active);
  }

  @override
  Widget build(BuildContext context) {
    final p = BrandPalette(widget.isDark);
    final keyBg =
        widget.isDark ? const Color(0xFF3A3A3E) : CupertinoColors.white;
    final boardBg =
        widget.isDark ? const Color(0xFF1E1E21) : const Color(0xFFE4E0D8);

    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final press = step(0.38, 0.46) - step(0.46, 0.54);
        final fixed = c.value >= 0.50;
        final glow = step(0.50, 0.66);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // The message being written in some other app.
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 270),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 17, color: p.text, height: 1.35),
                    children: [
                      const TextSpan(text: 'Can we meet '),
                      TextSpan(
                        text: fixed ? 'tomorrow' : 'tomorow',
                        style: TextStyle(
                          color: fixed ? BrandPalette.green : p.text,
                          fontWeight: fixed ? FontWeight.w600 : null,
                          backgroundColor: fixed
                              ? Color.lerp(p.card, p.greenBg, glow)
                              : null,
                          decoration: fixed
                              ? TextDecoration.none
                              : TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.wavy,
                          decorationColor: BrandPalette.red,
                        ),
                      ),
                      const TextSpan(text: ' at 10?'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            // Keyboard with the Bonkilingo toolbar.
            Container(
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
              decoration: BoxDecoration(
                color: boardBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: BrandColors.sunny,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('Bonkilingo',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: p.text)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: p.muted),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('EN',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: p.text)),
                        ),
                        const Spacer(),
                        Transform.scale(
                          scale: 1 - 0.08 * press,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: BrandColors.iconGradient,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              fixed ? 'Fixed ✓' : 'Correct',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: BrandColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final row in const [
                    'qwertyuiop',
                    'asdfghjkl',
                    'zxcvbnm'
                  ])
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final ch in row.split(''))
                            Container(
                              width: 24,
                              height: 32,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: keyBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(ch,
                                  style:
                                      TextStyle(fontSize: 14, color: p.text)),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Practice: a fill-the-gap quiz built from your own past mistake.

class PracticeDemo extends StatefulWidget {
  final bool active;
  final bool isDark;
  const PracticeDemo({super.key, required this.active, required this.isDark});

  @override
  State<PracticeDemo> createState() => _PracticeDemoState();
}

class _PracticeDemoState extends _DemoState<PracticeDemo> {
  @override
  Duration get duration => const Duration(milliseconds: 3400);
  @override
  bool get active => widget.active;

  @override
  void didUpdateWidget(PracticeDemo old) {
    super.didUpdateWidget(old);
    onActiveChanged(old.active);
  }

  static const _options = ['goed', 'went', 'gone', 'go'];
  static const _tools = [
    (Icons.bolt, 'Tiny Lesson', BrandColors.tangerine),
    (Icons.quiz_outlined, 'Vocabulary', Color(0xFF4F8EF7)),
    (Icons.spellcheck, 'Grammar', BrandColors.leaf),
    (Icons.view_agenda_outlined, 'Sentences', Color(0xFFB07CF5)),
  ];

  @override
  Widget build(BuildContext context) {
    final p = BrandPalette(widget.isDark);

    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final picked = c.value >= 0.45;
        final pickGlow = step(0.45, 0.58);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _card(
              p,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history,
                          size: 14, color: BrandColors.tangerine),
                      const SizedBox(width: 4),
                      Text('From your corrections',
                          style: TextStyle(fontSize: 12, color: p.muted)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Fill the gap',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: p.text)),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: p.cardSunken,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: 17, color: p.text),
                        children: [
                          const TextSpan(text: 'I '),
                          TextSpan(
                            text: picked ? ' went ' : ' _____ ',
                            style: TextStyle(
                              color: picked ? BrandPalette.green : p.muted,
                              fontWeight: FontWeight.w700,
                              backgroundColor: picked ? p.greenBg : null,
                            ),
                          ),
                          const TextSpan(text: ' to the store.'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 3.4,
                    children: [
                      for (final o in _options)
                        Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: o == 'went'
                                ? Color.lerp(p.cardSunken, p.greenBg, pickGlow)
                                : p.cardSunken,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: o == 'went'
                                  ? BrandPalette.green
                                      .withValues(alpha: pickGlow)
                                  : const Color(0x00000000),
                              width: 1.5,
                            ),
                          ),
                          child: Text(o,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: p.text)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < _tools.length; i++)
                  reveal(
                    0.62 + i * 0.06,
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _tools[i]
                            .$3
                            .withValues(alpha: widget.isDark ? 0.22 : 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_tools[i].$1, size: 16, color: _tools[i].$3),
                          const SizedBox(width: 6),
                          Text(_tools[i].$2,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: p.text)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Rewards: BONK balance counting up, a streak filling in, earnings.

class RewardsDemo extends StatefulWidget {
  final bool active;
  final bool isDark;
  const RewardsDemo({super.key, required this.active, required this.isDark});

  @override
  State<RewardsDemo> createState() => _RewardsDemoState();
}

class _RewardsDemoState extends _DemoState<RewardsDemo> {
  @override
  Duration get duration => const Duration(milliseconds: 3200);
  @override
  bool get active => widget.active;

  @override
  void didUpdateWidget(RewardsDemo old) {
    super.didUpdateWidget(old);
    onActiveChanged(old.active);
  }

  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final p = BrandPalette(widget.isDark);

    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final balance = (1250 * step(0.05, 0.55)).round();
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: BrandColors.iconGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your BONK balance',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xB31C1C1E))),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        balance.formatted.isEmpty ? '0' : balance.formatted,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: BrandColors.ink,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 6, bottom: 8),
                        child: Text('BONK',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: BrandColors.ink)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _card(
              p,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department,
                          size: 20, color: BrandColors.tangerine),
                      const SizedBox(width: 6),
                      Text('5 day streak',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: p.text)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < _days.length; i++)
                        Column(
                          children: [
                            Text(_days[i],
                                style: TextStyle(fontSize: 12, color: p.muted)),
                            const SizedBox(height: 6),
                            _StreakDot(
                              fill: i < 5
                                  ? step(0.20 + i * 0.08, 0.30 + i * 0.08)
                                  : 0,
                              empty: p.cardSunken,
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            reveal(
                0.66, _earnRow(p, Icons.edit_note, 'Text correction', '+250')),
            const SizedBox(height: 8),
            reveal(
                0.76,
                _earnRow(
                    p, Icons.local_fire_department, 'Daily streak', '+150')),
          ],
        );
      },
    );
  }

  Widget _earnRow(BrandPalette p, IconData icon, String title, String amount) {
    return _card(
      p,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: p.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 15, color: p.text)),
          ),
          Text('$amount BONK',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: BrandPalette.green)),
        ],
      ),
    );
  }
}

class _StreakDot extends StatelessWidget {
  final double fill;
  final Color empty;
  const _StreakDot({required this.fill, required this.empty});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Color.lerp(empty, BrandColors.leaf, fill),
        shape: BoxShape.circle,
      ),
      child: fill > 0.6
          ? Icon(Icons.check,
              size: 16,
              color: BrandColors.ink.withValues(alpha: (fill - 0.6) / 0.4))
          : null,
    );
  }
}
