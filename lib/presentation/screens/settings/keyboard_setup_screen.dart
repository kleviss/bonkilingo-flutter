import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_helper.dart';
import '../../providers/keyboard_settings_provider.dart';
import '../../providers/theme_provider.dart';

/// Walks the user through adding the Bonkilingo keyboard in iPhone Settings.
///
/// iOS doesn't let an app add, remove or grant Full Access to a keyboard; only
/// the user can, in Settings. So this screen explains the steps, opens the
/// app's own Settings page (which lists "Keyboards" once the extension
/// exists), and offers the one switch the app does control: whether the
/// keyboard's Correct button is on.
class KeyboardSetupScreen extends ConsumerWidget {
  const KeyboardSetupScreen({super.key});

  static const _steps = <(String, String?)>[
    ('Tap "Open iPhone Settings" below.', null),
    ('Tap Keyboards.', null),
    ('Turn on Bonkilingo.', null),
    (
      'Turn on Allow Full Access.',
      'Bonkilingo needs this to send the text you choose to correct to its server.',
    ),
    (
      'In any app, touch and hold the globe key on the keyboard and choose Bonkilingo.',
      null,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ThemeHelper(ref.watch(themeModeProvider));
    final correctionsEnabled = ref.watch(keyboardCorrectionsEnabledProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        // The default back chevron needs the CupertinoIcons font, which the
        // app doesn't bundle; use the same back button as Settings.
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        middle: const Text('Bonkilingo Keyboard'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Correct your messages right where you write them, in WhatsApp, '
              'iMessage, Gmail and other apps.',
              style: TextStyle(fontSize: 16, color: theme.textSecondary),
            ),
            const SizedBox(height: 20),

            _card(
              theme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cardTitle('Add the keyboard', theme),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _steps.length; i++)
                    _step(i + 1, _steps[i].$1, _steps[i].$2, theme),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: () => _openAppSettings(context),
                      child: const Text(
                        'Open iPhone Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Don't see Keyboards? Go to Settings › General › Keyboard › "
                    'Keyboards › Add New Keyboard, and choose Bonkilingo.',
                    style: TextStyle(fontSize: 13, color: theme.textTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _card(
              theme,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _cardTitle('Correct button', theme),
                        const SizedBox(height: 4),
                        Text(
                          'Turn off to use Bonkilingo as a plain keyboard. '
                          'Nothing is sent while it is off.',
                          style: TextStyle(fontSize: 14, color: theme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  correctionsEnabled == null
                      ? const CupertinoActivityIndicator()
                      : CupertinoSwitch(
                          value: correctionsEnabled,
                          activeTrackColor: AppColors.primary,
                          onChanged: (value) => ref
                              .read(keyboardCorrectionsEnabledProvider.notifier)
                              .setEnabled(value),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _card(
              theme,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, color: theme.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your text only leaves your iPhone when you tap Correct. '
                      "It's sent to Bonkilingo's server and to OpenAI to correct it. "
                      'The keyboard never sees password fields.\n\n'
                      'To remove the keyboard, turn off Bonkilingo in the same '
                      'Keyboards screen.',
                      style: TextStyle(fontSize: 14, color: theme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(ThemeHelper theme, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: child,
    );
  }

  Widget _cardTitle(String text, ThemeHelper theme) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: theme.textPrimary,
      ),
    );
  }

  Widget _step(int number, String text, String? detail, ThemeHelper theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.black,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: TextStyle(fontSize: 15, color: theme.textPrimary)),
                if (detail != null) ...[
                  const SizedBox(height: 2),
                  Text(detail, style: TextStyle(fontSize: 13, color: theme.textTertiary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Opens this app's page in the Settings app. Once the keyboard extension
  /// is installed, iOS lists "Keyboards" there with the Bonkilingo and
  /// Allow Full Access switches.
  Future<void> _openAppSettings(BuildContext context) async {
    final opened = await launchUrl(Uri.parse('app-settings:'));
    if (!opened && context.mounted) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => CupertinoAlertDialog(
          content: const Text('Open the Settings app and go to General › Keyboard › Keyboards.'),
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
}
