import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/brand/auth_layout.dart';
import '../../widgets/brand/pill_button.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    // Editing any field clears the last error.
    _emailController.addListener(_clearError);
    _passwordController.addListener(_clearError);
    _confirmPasswordController.addListener(_clearError);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  Future<void> _handleSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

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

    if (password != confirmPassword) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    await ref.read(authStateProvider.notifier).signUp(email, password);

    final authState = ref.read(authStateProvider);

    if (authState.error != null && mounted) {
      setState(() => _error = authState.error);
    } else if (authState.user != null && mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Success!'),
          content: const Text('Account created successfully!'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Back to signup
                Navigator.of(context).pop(); // Back to previous screen
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final p = BrandPalette(isDark);

    return AuthLayout(
      isDark: isDark,
      title: 'Create your *account*',
      subtitle: 'Save your corrections and start earning BONK.',
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
          placeholder: 'At least 6 characters',
          obscure: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          enabled: !authState.isLoading,
        ),
        const SizedBox(height: 16),
        BrandTextField(
          isDark: isDark,
          label: 'Confirm password',
          controller: _confirmPasswordController,
          icon: Icons.lock_outline,
          placeholder: 'Type it again',
          obscure: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          enabled: !authState.isLoading,
          onSubmitted: (_) => _handleSignup(),
        ),
        const SizedBox(height: 24),
        if (_error != null) ...[
          AuthError(message: _error!, isDark: isDark),
          const SizedBox(height: 16),
        ],
        PillButton(
          label: 'Create account',
          loading: authState.isLoading,
          onPressed: _handleSignup,
        ),
        const SizedBox(height: 16),

        // Terms Text
        Text(
          'By signing up, you agree to our Terms of Service and Privacy Policy',
          style: TextStyle(fontSize: 12, height: 1.4, color: p.muted),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),
        AuthSwitchLink(
          isDark: isDark,
          prompt: 'Already have an account?',
          action: 'Sign in',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
