import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/brand_colors.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/brand/brand_mark.dart';
import '../../widgets/brand/glow_background.dart';
import '../../widgets/brand/highlighted_title.dart';
import '../../widgets/brand/pill_button.dart';
import '../auth/login_screen.dart';
import '../main_navigation.dart';
import 'onboarding_demos.dart';

/// First-launch walkthrough: one page per feature, each with a live demo.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const prefsKey = 'onboarding_complete';

  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKey) ?? false;
  }

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Page {
  final String title;
  final String body;
  final Widget Function(bool active, bool isDark) demo;
  final bool showBrand;
  const _Page(this.title, this.body, this.demo, {this.showBrand = false});
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  late final List<_Page> _pages = [
    _Page(
      'Write it. *Fix* it.',
      'Bonkilingo corrects your writing and tells you why.',
      (a, d) => CorrectionDemo(active: a, isDark: d),
      showBrand: true,
    ),
    if (AppConstants.keyboardExtensionEnabled)
      _Page(
        'Correct *anywhere*',
        'Use the Bonkilingo keyboard to fix messages in any app.',
        (a, d) => KeyboardDemo(active: a, isDark: d),
      ),
    _Page(
      'Learn from your *mistakes*',
      'Short quizzes and lessons built from your own corrections.',
      (a, d) => PracticeDemo(active: a, isDark: d),
    ),
    _Page(
      'Earn *BONK*',
      'Get BONK for every correction, lesson and day of your streak.',
      (a, d) => RewardsDemo(active: a, isDark: d),
    ),
  ];

  bool get _isLast => _index == _pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish({bool signIn = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingScreen.prefsKey, true);
    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainNavigation(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    if (signIn) {
      navigator.push(
        CupertinoPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.jumpToPage(_index + 1);
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final textColor = isDark ? const Color(0xFFF5F5F7) : BrandColors.ink;
    final mutedColor =
        isDark ? const Color(0xFFA1A1A6) : const Color(0xFF6E685F);

    return CupertinoPageScaffold(
      child: GlowBackground(
        isDark: isDark,
        child: SafeArea(
          child: Column(
            children: [
              // Skip
              SizedBox(
                height: 44,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    opacity: _isLast ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      onPressed: _isLast ? null : () => _finish(),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: mutedColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Pages
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final page = _pages[i];
                    final active = i == _index;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: SizedBox(
                                  width: 340,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (page.showBrand) ...[
                                        const BrandMark(size: 76),
                                        const SizedBox(height: 14),
                                        _Wordmark(color: textColor),
                                        const SizedBox(height: 22),
                                      ],
                                      page.demo(active, isDark),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          HighlightedTitle(
                            page.title,
                            animate: active,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.9,
                              height: 1.15,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            page.body,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              height: 1.4,
                              color: mutedColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
              _Dots(count: _pages.length, index: _index, color: textColor),
              const SizedBox(height: 24),

              // Primary action
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: PillButton(
                  label: _isLast ? 'Get started' : 'Next',
                  onPressed: _next,
                ),
              ),

              // Sign in link (last page only; space kept so nothing jumps)
              SizedBox(
                height: 52,
                child: AnimatedOpacity(
                  opacity: _isLast ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: CupertinoButton(
                    onPressed: _isLast ? () => _finish(signIn: true) : null,
                    child: Text(
                      'I already have an account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        decoration: TextDecoration.underline,
                        decorationColor: mutedColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  final Color color;
  const _Wordmark({required this.color});

  @override
  Widget build(BuildContext context) {
    return HighlightedTitle(
      'Bonki*lingo*',
      style: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: color,
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  final Color color;
  const _Dots({required this.count, required this.index, required this.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Page ${index + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == index ? 24 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == index ? color : color.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
