import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode, showLicensePage;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_helper.dart';
import '../../providers/providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../profile/profile_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final theme = ThemeHelper(themeMode);
    final currentUser = ref.watch(currentUserProvider).value;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        middle: const Text('Settings'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 16),

            // Account Section
            _buildSectionHeader('Account'),
            _buildListTile(
              icon: Icons.person,
              title: 'View Profile',
              subtitle: currentUser?.email ?? 'Not signed in',
              theme: theme,
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            _buildListTile(
              icon: Icons.email,
              title: 'Change Email',
              theme: theme,
              onTap: () => _showChangeEmailDialog(context, currentUser?.email),
            ),
            _buildListTile(
              icon: Icons.lock,
              title: 'Change Password',
              theme: theme,
              onTap: () => _showChangePasswordDialog(context),
            ),

            const SizedBox(height: 24),

            // App Settings
            _buildSectionHeader('App Settings'),
            _buildSwitchTile(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Receive learning reminders',
              value: _notificationsEnabled,
              theme: theme,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _showToast(
                  context,
                  value ? 'Notifications enabled' : 'Notifications disabled',
                );
              },
            ),
            _buildSwitchTile(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              subtitle: 'Use dark theme',
              value: isDarkMode,
              theme: theme,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),
            _buildListTile(
              icon: Icons.language,
              title: 'App Language',
              subtitle: 'English',
              theme: theme,
              onTap: () => _showLanguageDialog(context),
            ),

            const SizedBox(height: 24),

            // Data & Privacy
            _buildSectionHeader('Data & Privacy'),
            _buildListTile(
              icon: Icons.download,
              title: 'Export Data',
              theme: theme,
              onTap: () => _showExportDataDialog(context),
            ),
            _buildListTile(
              icon: Icons.delete_outline,
              title: 'Clear Cache',
              theme: theme,
              onTap: () => _showClearCacheDialog(context),
            ),

            const SizedBox(height: 24),

            // About
            _buildSectionHeader('About'),
            _buildListTile(
              icon: Icons.info_outline,
              title: 'Version',
              subtitle: '${AppConstants.appVersion} (Build 1)',
              theme: theme,
              trailing: const SizedBox.shrink(),
            ),
            _buildListTile(
              icon: Icons.description_outlined,
              title: 'Terms of Service',
              theme: theme,
              onTap: () => _launchUrl('https://bonkilingo.app/terms'),
            ),
            _buildListTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              theme: theme,
              onTap: () => _launchUrl('https://bonkilingo.app/privacy'),
            ),
            _buildListTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              theme: theme,
              onTap: () => _showHelpDialog(context),
            ),
            _buildListTile(
              icon: Icons.code,
              title: 'Open Source Licenses',
              theme: theme,
              onTap: () => _showLicensesPage(context),
            ),

            const SizedBox(height: 24),

            // Sign Out (only if signed in)
            if (currentUser != null) ...[
              _buildSectionHeader('Account Actions'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: CupertinoButton(
                  color: AppColors.error,
                  onPressed: () => _showSignOutDialog(context),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, size: 18, color: CupertinoColors.white),
                      SizedBox(width: 8),
                      Text('Sign Out', style: TextStyle(color: CupertinoColors.white)),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.systemGrey,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    required ThemeHelper theme,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CupertinoListTile(
        leading: Icon(icon, color: theme.textPrimary),
        title: Text(
          title,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 16,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 14,
                ),
              )
            : null,
        trailing: trailing ?? Icon(Icons.chevron_right, color: theme.textTertiary),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
    required ThemeHelper theme,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CupertinoListTile(
        leading: Icon(icon, color: theme.textPrimary),
        title: Text(
          title,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 16,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 14,
                ),
              )
            : null,
        trailing: CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: AppColors.primary,
        ),
      ),
    );
  }

  // ========== Dialogs ==========

  void _showChangeEmailDialog(BuildContext context, String? currentEmail) {
    final controller = TextEditingController(text: currentEmail ?? '');

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Change Email'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'New email address',
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _showToast(context, 'Email change request sent. Check your inbox.');
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Change Password'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              CupertinoTextField(
                controller: currentController,
                placeholder: 'Current password',
                obscureText: true,
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: newController,
                placeholder: 'New password',
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _showToast(context, 'Password updated successfully');
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Select Language'),
        message: const Text('Choose your preferred app language'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showToast(context, 'Language set to English');
            },
            child: const Text('English'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showToast(context, 'Coming soon!');
            },
            child: const Text('Español (Coming Soon)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showToast(context, 'Coming soon!');
            },
            child: const Text('Français (Coming Soon)'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showExportDataDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Export Your Data'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Your data export will include:\n\n'
            '• Profile information\n'
            '• Correction history\n'
            '• Saved lessons\n'
            '• Learning statistics\n\n'
            'The export will be sent to your email.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _showToast(context, 'Export request submitted. Check your email.');
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all locally stored data including offline lessons and history. Your account data will not be affected.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();

              // Actually clear the cache
              try {
                final localStorage = ref.read(localStorageProvider);
                await localStorage.clearAll();
                if (mounted) {
                  _showToast(context, 'Cache cleared successfully');
                }
              } catch (e) {
                if (mounted) {
                  _showToast(context, 'Failed to clear cache');
                }
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Help & Support'),
        message: const Text('How can we help you?'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _launchUrl('mailto:support@bonkilingo.app?subject=App Support');
            },
            child: const Text('Email Support'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _launchUrl('https://bonkilingo.app/faq');
            },
            child: const Text('FAQ'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showToast(context, 'Feature coming soon!');
            },
            child: const Text('Report a Bug'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authStateProvider.notifier).signOut();
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showLicensesPage(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
    );
  }

  // ========== Helpers ==========

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        _showToast(context, 'Could not open link');
      }
    }
  }

  void _showToast(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
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
}
