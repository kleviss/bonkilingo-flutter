import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/brand/auth_layout.dart';
import '../../widgets/brand/pill_button.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    // Editing either field clears the last error.
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _error = null);

    // Validate
    if (Validators.email(email) != null) {
      setState(() => _error = 'Please enter a valid email');
      return;
    }

    if (Validators.password(password) != null) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    await ref.read(authStateProvider.notifier).signIn(email, password);

    final authState = ref.read(authStateProvider);

    if (authState.error != null && mounted) {
      setState(() => _error = authState.error);
    } else if (authState.user != null && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return AuthLayout(
      isDark: isDark,
      title: 'Welcome *back*',
      subtitle: 'Sign in to keep your streak and BONK.',
      children: [
        BrandTextField(
          isDark: isDark,
          label: 'Email',
          controller: _emailController,
          icon: Icons.mail_outline,
          placeholder: 'you@example.com',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          enabled: !authState.isLoading,
        ),
        const SizedBox(height: 16),
        BrandTextField(
          isDark: isDark,
          label: 'Password',
          controller: _passwordController,
          icon: Icons.lock_outline,
          placeholder: 'Your password',
          obscure: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          enabled: !authState.isLoading,
          onSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 24),
        if (_error != null) ...[
          AuthError(message: _error!, isDark: isDark),
          const SizedBox(height: 16),
        ],
        PillButton(
          label: 'Sign in',
          loading: authState.isLoading,
          onPressed: _handleLogin,
        ),
        const SizedBox(height: 8),

        // Forgot Password
        Center(
          child: CupertinoButton(
            onPressed: () {
              // TODO: Implement forgot password
            },
            child: Text(
              'Forgot password?',
              // Muted ink, not the yellow accent, which is unreadable on
              // the cream background.
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: BrandPalette(isDark).muted,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
        AuthSwitchLink(
          isDark: isDark,
          prompt: "Don't have an account?",
          action: 'Sign up',
          onPressed: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => const SignupScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}
