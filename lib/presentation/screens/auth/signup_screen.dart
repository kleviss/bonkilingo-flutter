import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_helper.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validate
    if (Validators.email(email) != null) {
      _showError('Please enter a valid email');
      return;
    }

    if (Validators.password(password) != null) {
      _showError('Password must be at least 6 characters');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    await ref.read(authStateProvider.notifier).signUp(email, password);

    final authState = ref.read(authStateProvider);

    if (authState.error != null && mounted) {
      _showError(authState.error!);
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

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = ThemeHelper(themeMode);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        middle: const Text('Sign Up'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Start your language learning journey',
                style: TextStyle(
                  fontSize: 16,
                  color: theme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Email Field
              Text(
                'Email',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _emailController,
                placeholder: 'your@email.com',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                padding: const EdgeInsets.all(16),
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    Icons.email,
                    color: theme.textTertiary,
                  ),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.border),
                ),
                enabled: !authState.isLoading,
              ),

              const SizedBox(height: 16),

              // Password Field
              Text(
                'Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _passwordController,
                placeholder: 'At least 6 characters',
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                padding: const EdgeInsets.all(16),
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    Icons.lock,
                    color: theme.textTertiary,
                  ),
                ),
                suffix: CupertinoButton(
                  padding: const EdgeInsets.only(right: 12),
                  minSize: 0,
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: theme.textTertiary,
                  ),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.border),
                ),
                enabled: !authState.isLoading,
              ),

              const SizedBox(height: 16),

              // Confirm Password Field
              Text(
                'Confirm Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              CupertinoTextField(
                controller: _confirmPasswordController,
                placeholder: 'Confirm your password',
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.done,
                padding: const EdgeInsets.all(16),
                prefix: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    Icons.lock,
                    color: theme.textTertiary,
                  ),
                ),
                suffix: CupertinoButton(
                  padding: const EdgeInsets.only(right: 12),
                  minSize: 0,
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                  child: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: theme.textTertiary,
                  ),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.border),
                ),
                enabled: !authState.isLoading,
                onSubmitted: (_) => _handleSignup(),
              ),

              const SizedBox(height: 32),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                child: CupertinoButton.filled(
                  onPressed: authState.isLoading ? null : _handleSignup,
                  child: authState.isLoading
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.black,
                        )
                      : const Text('Sign Up'),
                ),
              ),

              const SizedBox(height: 24),

              // Terms Text
              Text(
                'By signing up, you agree to our Terms of Service and Privacy Policy',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Sign In Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Sign In'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
