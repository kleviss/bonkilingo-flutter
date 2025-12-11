import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_helper.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final theme = ThemeHelper(themeMode);
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
              title: 'Edit Profile',
              theme: theme,
              onTap: () {
                // TODO: Navigate to edit profile
              },
            ),
            _buildListTile(
              icon: Icons.email,
              title: 'Change Email',
              theme: theme,
              onTap: () {
                // TODO: Navigate to change email
              },
            ),
            _buildListTile(
              icon: Icons.lock,
              title: 'Change Password',
              theme: theme,
              onTap: () {
                // TODO: Navigate to change password
              },
            ),

            const SizedBox(height: 24),

            // App Settings
            _buildSectionHeader('App Settings'),
            _buildSwitchTile(
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Receive learning reminders',
              value: true,
              theme: theme,
              onChanged: (value) {
                // TODO: Toggle notifications
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
              onTap: () {
                // TODO: Change app language
              },
            ),

            const SizedBox(height: 24),

            // Data & Privacy
            _buildSectionHeader('Data & Privacy'),
            _buildListTile(
              icon: Icons.download,
              title: 'Export Data',
              theme: theme,
              onTap: () {
                // TODO: Export user data
              },
            ),
            _buildListTile(
              icon: Icons.delete,
              title: 'Clear Cache',
              theme: theme,
              onTap: () {
                _showClearCacheDialog(context);
              },
            ),

            const SizedBox(height: 24),

            // About
            _buildSectionHeader('About'),
            _buildListTile(
              icon: Icons.info,
              title: 'Version',
              subtitle: AppConstants.appVersion,
              theme: theme,
              trailing: const SizedBox.shrink(),
            ),
            _buildListTile(
              icon: Icons.description,
              title: 'Terms of Service',
              theme: theme,
              onTap: () {
                // TODO: Show terms of service
              },
            ),
            _buildListTile(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              theme: theme,
              onTap: () {
                // TODO: Show privacy policy
              },
            ),
            _buildListTile(
              icon: Icons.help_outline,
              title: 'Help & Support',
              theme: theme,
              onTap: () {
                // TODO: Show help & support
              },
            ),

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
        trailing: trailing ??
            Icon(Icons.chevron_right, color: theme.textTertiary),
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
          activeColor: AppColors.primary,
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will clear all locally stored data. Are you sure?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Clear cache
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('Success'),
                  content: const Text('Cache cleared successfully'),
                  actions: [
                    CupertinoDialogAction(
                      isDefaultAction: true,
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
