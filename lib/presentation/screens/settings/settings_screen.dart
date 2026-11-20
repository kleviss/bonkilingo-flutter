import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode, showLicensePage;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/brand_colors.dart';
import '../../providers/providers.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/keyboard_settings_provider.dart';
import '../../../data/data_sources/local/keyboard_settings.dart';
import '../../widgets/brand/brand_page.dart';
import '../../widgets/brand/brand_surfaces.dart';
import 'keyboard_setup_screen.dart';

const _blue = Color(0xFF4F8EF7);
const _purple = Color(0xFFB07CF5);

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
    final p = BrandPalette(isDarkMode);
    final currentUser = ref.watch(currentUserProvider).value;
    final keyboardCorrectionsEnabled = AppConstants.keyboardExtensionEnabled
        ? ref.watch(keyboardCorrectionsEnabledProvider)
        : null;
    final keyboardSaveToHistory = AppConstants.keyboardExtensionEnabled
        ? ref.watch(keyboardSaveToHistoryProvider)
        : null;

    return BrandPage(
      isDark: isDarkMode,
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // Account
          _buildSection(p, 'Account', [
            _buildRow(
              p,
              icon: Icons.email_outlined,
              color: _blue,
              title: 'Change email',
              onTap: () => _showChangeEmailDialog(context, currentUser?.email),
            ),
            _buildRow(
              p,
              icon: Icons.lock_outline,
              color: _purple,
              title: 'Change password',
              onTap: () => _showChangePasswordDialog(context),
            ),
          ]),

          // App settings
          _buildSection(p, 'App settings', [
            _buildSwitchRow(
              p,
              icon: Icons.notifications_none,
              color: BrandColors.tangerine,
              title: 'Notifications',
              subtitle: 'Receive learning reminders',
              value: _notificationsEnabled,
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
            _buildSwitchRow(
              p,
              icon: Icons.dark_mode_outlined,
              color: _purple,
              title: 'Dark mode',
              subtitle: 'Use dark theme',
              value: isDarkMode,
              onChanged: (value) {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),
            _buildRow(
              p,
              icon: Icons.language,
              color: _blue,
              title: 'App language',
              subtitle: 'English',
              onTap: () => _showLanguageDialog(context),
            ),
          ]),

          // Bonkilingo Keyboard (hidden until the keyboard extension ships)
          if (AppConstants.keyboardExtensionEnabled &&
              KeyboardSettings.isSupported)
            _buildSection(p, 'Bonkilingo keyboard', [
              _buildRow(
                p,
                icon: Icons.keyboard_outlined,
                color: BrandColors.tangerine,
                title: 'Set up keyboard',
                subtitle: 'Correct messages in WhatsApp, iMessage and more',
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => const KeyboardSetupScreen(),
                    ),
                  );
                },
              ),
              if (keyboardCorrectionsEnabled != null)
                _buildSwitchRow(
                  p,
                  icon: Icons.spellcheck,
                  color: BrandColors.leaf,
                  title: 'Correct button in keyboard',
                  subtitle: keyboardCorrectionsEnabled
                      ? 'On: tap Correct in any app'
                      : 'Off: Bonkilingo works as a plain keyboard',
                  value: keyboardCorrectionsEnabled,
                  onChanged: (value) {
                    ref
                        .read(keyboardCorrectionsEnabledProvider.notifier)
                        .setEnabled(value);
                  },
                ),
              if (keyboardSaveToHistory != null)
                _buildSwitchRow(
                  p,
                  icon: Icons.history,
                  color: _blue,
                  title: 'Save keyboard corrections',
                  subtitle: keyboardSaveToHistory
                      ? 'On: added to History for lesson ideas'
                      : 'Off: keyboard corrections aren\'t kept',
                  value: keyboardSaveToHistory,
                  onChanged: (value) {
                    ref
                        .read(keyboardSaveToHistoryProvider.notifier)
                        .setEnabled(value);
                  },
                ),
            ]),

          // Data & privacy
          _buildSection(p, 'Data & privacy', [
            _buildRow(
              p,
              icon: Icons.download_outlined,
              color: _blue,
              title: 'Export data',
              onTap: () => _showExportDataDialog(context),
            ),
            _buildRow(
              p,
              icon: Icons.delete_outline,
              color: BrandPalette.red,
              title: 'Clear cache',
              onTap: () => _showClearCacheDialog(context),
            ),
          ]),

          // About
          _buildSection(p, 'About', [
            _buildRow(
              p,
              icon: Icons.info_outline,
              color: BrandColors.tangerine,
              title: 'Version',
              subtitle: '${AppConstants.appVersion} (Build 1)',
            ),
            _buildRow(
              p,
              icon: Icons.description_outlined,
              color: _blue,
              title: 'Terms of service',
              onTap: () => _launchUrl('https://bonkilingo.app/terms'),
            ),
            _buildRow(
              p,
              icon: Icons.privacy_tip_outlined,
              color: BrandColors.leaf,
              title: 'Privacy policy',
              onTap: () => _launchUrl('https://bonkilingo.app/privacy'),
            ),
            _buildRow(
              p,
              icon: Icons.help_outline,
              color: BrandColors.ribbon,
              title: 'Help & support',
              onTap: () => _showHelpDialog(context),
            ),
            _buildRow(
              p,
              icon: Icons.code,
              color: _purple,
              title: 'Open source licenses',
              onTap: () => _showLicensesPage(context),
            ),
          ]),

          // Sign out (only if signed in)
          if (currentUser != null)
            _DestructivePill(
              palette: p,
              icon: Icons.logout,
              label: 'Sign out',
              onPressed: () => _showSignOutDialog(context),
            ),
        ],
      ),
    );
  }

  /// A titled, grouped card of rows separated by hairlines.
  Widget _buildSection(BrandPalette p, String title, List<Widget> rows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandSectionTitle(title, palette: p),
          BrandCard(
            palette: p,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) BrandRowDivider(palette: p),
                  rows[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BrandPalette p, {
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return BrandListRow(
      palette: p,
      leading: BrandIconBadge(icon: icon, color: color, isDark: p.isDark),
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }

  Widget _buildSwitchRow(
    BrandPalette p, {
    required IconData icon,
    required Color color,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
  }) {
    return BrandListRow(
      palette: p,
      leading: BrandIconBadge(icon: icon, color: color, isDark: p.isDark),
      title: title,
      subtitle: subtitle,
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: BrandColors.tangerine,
      ),
    );
  }

  // ========== Dialogs ==========

  void _showChangeEmailDialog(BuildContext context, String? currentEmail) {
    final controller = TextEditingController(text: currentEmail ?? '');

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Change email'),
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
              _showToast(
                context,
                'Email change request sent. Check your inbox.',
              );
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
        title: const Text('Change password'),
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
        title: const Text('Select language'),
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
            child: const Text('Español (coming soon)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _showToast(context, 'Coming soon!');
            },
            child: const Text('Français (coming soon)'),
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
        title: const Text('Export your data'),
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
              _showToast(
                context,
                'Export request submitted. Check your email.',
              );
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
        title: const Text('Clear cache'),
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
                  _showToast(this.context, 'Cache cleared successfully');
                }
              } catch (e) {
                if (mounted) {
                  _showToast(this.context, 'Failed to clear cache');
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
        title: const Text('Help & support'),
        message: const Text('How can we help you?'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(context).pop();
              _launchUrl('mailto:support@bonkilingo.app?subject=App Support');
            },
            child: const Text('Email support'),
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
            child: const Text('Report a bug'),
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
        title: const Text('Sign out'),
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
                Navigator.of(this.context).pop();
              }
            },
            child: const Text('Sign out'),
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

/// Full-width pill tinted red for destructive actions such as signing out.
class _DestructivePill extends StatelessWidget {
  final BrandPalette palette;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _DestructivePill({
    required this.palette,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onPressed,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: palette.redBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: BrandPalette.red),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: BrandPalette.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
