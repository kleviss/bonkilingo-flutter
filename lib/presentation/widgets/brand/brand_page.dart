import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import '../../../core/theme/brand_colors.dart';
import 'glow_background.dart';

/// Frame for pages pushed from a tab: brand glow behind everything, a clear
/// navigation bar with a back chevron and a centred title.
///
/// [child] is placed inside a [SafeArea]; scroll views go in [child].
class BrandPage extends StatelessWidget {
  final bool isDark;
  final String? title;
  final Widget child;
  final Widget? trailing;

  /// Back button action. Defaults to popping the route.
  final VoidCallback? onBack;

  const BrandPage({
    super.key,
    required this.isDark,
    required this.child,
    this.title,
    this.trailing,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final p = BrandPalette(isDark);

    return GlowBackground(
      isDark: isDark,
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0x00000000),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: const Color(0x00000000),
          border: null,
          brightness: isDark ? Brightness.dark : Brightness.light,
          // Several of these pages live inside tab roots kept alive in an
          // IndexedStack; the default hero transition breaks pushes there.
          transitionBetweenRoutes: false,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            child: Semantics(
              label: 'Back',
              child: Icon(Icons.arrow_back_ios_new, size: 20, color: p.text),
            ),
          ),
          middle: title == null
              ? null
              : Text(
                  title!,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
          trailing: trailing,
        ),
        child: SafeArea(child: child),
      ),
    );
  }
}
