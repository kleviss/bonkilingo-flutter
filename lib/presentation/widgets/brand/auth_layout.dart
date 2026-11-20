import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import '../../../core/theme/brand_colors.dart';
import 'brand_mark.dart';
import 'glow_background.dart';
import 'highlighted_title.dart';

/// Shared frame for sign-in and sign-up: brand glow, a back button, the app
/// mark, a highlighted title, then the form.
class AuthLayout extends StatelessWidget {
  final bool isDark;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const AuthLayout({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.children,
    super.key,
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
          // The bar is clear over the glow; its blur would leave a visible
          // seam where the blurred strip ends.
          enableBackgroundFilterBlur: false,
          transitionBetweenRoutes: false,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).maybePop(),
            child: Semantics(
              label: 'Back',
              child: Icon(Icons.arrow_back_ios_new, size: 20, color: p.text),
            ),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: BrandMark(size: 64)),
                const SizedBox(height: 20),
                HighlightedTitle(
                  title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.9,
                    height: 1.15,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.4, color: p.muted),
                ),
                const SizedBox(height: 32),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Labelled text field on a rounded card that glows tangerine when focused.
class BrandTextField extends StatefulWidget {
  final bool isDark;
  final String label;
  final TextEditingController controller;
  final String? placeholder;
  final IconData icon;
  final bool obscure;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  const BrandTextField({
    required this.isDark,
    required this.label,
    required this.controller,
    required this.icon,
    super.key,
    this.placeholder,
    this.obscure = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  @override
  State<BrandTextField> createState() => _BrandTextFieldState();
}

class _BrandTextFieldState extends State<BrandTextField> {
  final _focus = FocusNode();
  late bool _hidden = widget.obscure;

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
    final p = BrandPalette(widget.isDark);
    final focused = _focus.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: p.text,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: focused ? BrandColors.tangerine : const Color(0x00000000),
              width: 1.5,
            ),
            boxShadow: p.cardShadow,
          ),
          child: CupertinoTextField(
            controller: widget.controller,
            focusNode: _focus,
            placeholder: widget.placeholder,
            obscureText: _hidden,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            autofillHints: widget.autofillHints,
            autocorrect: !widget.obscure &&
                widget.keyboardType != TextInputType.emailAddress,
            onSubmitted: widget.onSubmitted,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: null,
            cursorColor: BrandColors.tangerine,
            style: TextStyle(fontSize: 17, color: p.text),
            placeholderStyle: TextStyle(fontSize: 17, color: p.muted),
            prefix: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Icon(
                widget.icon,
                size: 20,
                color: focused ? BrandColors.tangerine : p.muted,
              ),
            ),
            suffix: widget.obscure
                ? CupertinoButton(
                    padding: const EdgeInsets.only(right: 14),
                    onPressed: () => setState(() => _hidden = !_hidden),
                    minimumSize: const Size(44, 44),
                    child: Semantics(
                      label: _hidden ? 'Show password' : 'Hide password',
                      child: Icon(
                        _hidden ? Icons.visibility : Icons.visibility_off,
                        size: 20,
                        color: p.muted,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// Inline error under a form, instead of an alert the user must dismiss.
class AuthError extends StatelessWidget {
  final String message;
  final bool isDark;

  const AuthError({required this.message, required this.isDark, super.key});

  @override
  Widget build(BuildContext context) {
    final p = BrandPalette(isDark);
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: p.redBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, size: 18, color: BrandPalette.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 14, height: 1.35, color: p.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Don't have an account? Sign up" style footer.
class AuthSwitchLink extends StatelessWidget {
  final bool isDark;
  final String prompt;
  final String action;
  final VoidCallback onPressed;

  const AuthSwitchLink({
    required this.isDark,
    required this.prompt,
    required this.action,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final p = BrandPalette(isDark);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(prompt, style: TextStyle(fontSize: 15, color: p.muted)),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          onPressed: onPressed,
          minimumSize: const Size(44, 44),
          child: Text(
            action,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: p.text,
              decoration: TextDecoration.underline,
              decorationColor: BrandColors.tangerine,
              decorationThickness: 2,
            ),
          ),
        ),
      ],
    );
  }
}
