import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../data/data_sources/local/keyboard_settings.dart';
import '../../providers/keyboard_settings_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/brand/brand_page.dart';
import '../../widgets/brand/brand_surfaces.dart';
import '../../widgets/brand/pill_button.dart';

const _blue = Color(0xFF4F8EF7);

/// Walks the user through adding the Bonkilingo keyboard.
///
/// Neither platform lets an app turn a keyboard on by itself; only the user
/// can, in system settings. So this screen explains the steps and opens the
/// right settings page. iOS: the app's own Settings page (which lists
/// "Keyboards" once the extension exists), then Allow Full Access. Android:
/// the system keyboard list, then the keyboard picker; Android also tells us
/// whether the keyboard is on, so the screen shows that.
///
/// It also offers the one switch the app does control: whether the
/// keyboard's Correct button is on.
class KeyboardSetupScreen extends ConsumerStatefulWidget {
  const KeyboardSetupScreen({super.key});

  @override
  ConsumerState<KeyboardSetupScreen> createState() =>
      _KeyboardSetupScreenState();
}

class _KeyboardSetupScreenState extends ConsumerState<KeyboardSetupScreen>
    with WidgetsBindingObserver {
  static const _iosSteps = <(String, String?)>[
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

  static const _androidSteps = <(String, String?)>[
    ('Tap "Open keyboard settings" below.', null),
    (
      'Turn on Bonkilingo and confirm.',
      'Android warns about every keyboard that isn\'t from Google. '
          'Bonkilingo only sends text when you tap Correct.',
    ),
    (
      'Come back here and tap "Switch to Bonkilingo".',
      'Later, switch keyboards with the keyboard icon at the bottom of the '
          'screen while typing, or by holding the 🌐 key.',
    ),
  ];

  /// Android only: whether the keyboard is on and in use. Null while loading
  /// and on iOS.
  KeyboardStatus? _status;

  bool get _isAndroid => KeyboardSettings.isAndroid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from system settings or the keyboard picker.
    if (state == AppLifecycleState.resumed) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    if (!_isAndroid) return;
    try {
      final status = await ref.read(keyboardSettingsProvider).getStatus();
      if (mounted) setState(() => _status = status);
    } catch (_) {
      // Leave the steps as they are.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final p = BrandPalette(isDark);
    final correctionsEnabled = ref.watch(keyboardCorrectionsEnabledProvider);
    final phone = _isAndroid ? 'phone' : 'iPhone';

    return BrandPage(
      isDark: isDark,
      title: 'Bonkilingo keyboard',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            _isAndroid
                ? 'Correct your messages right where you write them, in '
                    'WhatsApp, Gmail, Messages and other apps.'
                : 'Correct your messages right where you write them, in '
                    'WhatsApp, iMessage, Gmail and other apps.',
            style: TextStyle(fontSize: 16, height: 1.4, color: p.muted),
          ),
          const SizedBox(height: 24),
          if (_status?.enabled ?? false) ...[
            _StatusCard(status: _status!, palette: p, isDark: isDark),
            const SizedBox(height: 16),
            if (!_status!.selected)
              PillButton(
                label: 'Switch to Bonkilingo',
                onPressed: () =>
                    ref.read(keyboardSettingsProvider).showKeyboardPicker(),
              ),
          ] else ...[
            BrandSectionTitle('Add the keyboard', palette: p),
            BrandCard(
              palette: p,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, step) in _steps.indexed)
                    _Step(
                      number: i + 1,
                      text: step.$1,
                      detail: step.$2,
                      palette: p,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PillButton(
              label: _isAndroid ? 'Open keyboard settings' : 'Open iPhone Settings',
              onPressed: () => _isAndroid
                  ? ref.read(keyboardSettingsProvider).openSystemKeyboardSettings()
                  : _openAppSettings(context),
            ),
            const SizedBox(height: 12),
            Text(
              _isAndroid
                  ? "Don't see Bonkilingo? Open Settings › System › Keyboard › "
                      'On-screen keyboard (names vary by phone) and turn it on there.'
                  : "Don't see Keyboards? Go to Settings › General › Keyboard › "
                      'Keyboards › Add New Keyboard, and choose Bonkilingo.',
              style: TextStyle(fontSize: 13, height: 1.35, color: p.muted),
            ),
          ],
          const SizedBox(height: 28),
          BrandCard(
            palette: p,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: BrandListRow(
              palette: p,
              leading: BrandIconBadge(
                icon: Icons.spellcheck,
                color: BrandColors.leaf,
                isDark: isDark,
              ),
              title: 'Correct button',
              subtitle: 'Turn off to use Bonkilingo as a plain keyboard. '
                  'Nothing is sent while it is off.',
              trailing: correctionsEnabled == null
                  ? const CupertinoActivityIndicator()
                  : CupertinoSwitch(
                      value: correctionsEnabled,
                      activeTrackColor: BrandColors.tangerine,
                      onChanged: (value) => ref
                          .read(keyboardCorrectionsEnabledProvider.notifier)
                          .setEnabled(value),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          BrandCard(
            palette: p,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrandIconBadge(
                  icon: Icons.lock_outline,
                  color: _blue,
                  isDark: isDark,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Your text only leaves your $phone when you tap Correct. '
                    "It's sent to Bonkilingo's server and to OpenAI to correct it. "
                    '${_isAndroid ? 'The keyboard never sends password fields.' : 'The keyboard never sees password fields.'}\n\n'
                    'To remove the keyboard, turn off Bonkilingo in the same '
                    '${_isAndroid ? 'keyboard settings' : 'Keyboards'} screen.',
                    style: TextStyle(fontSize: 14, height: 1.4, color: p.muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<(String, String?)> get _steps => _isAndroid ? _androidSteps : _iosSteps;

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
          content: const Text(
            'Open the Settings app and go to General › Keyboard › Keyboards.',
          ),
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

/// A numbered setup step with an optional note under it.
class _Step extends StatelessWidget {
  final int number;
  final String text;
  final String? detail;
  final BrandPalette palette;

  const _Step({
    required this.number,
    required this.text,
    required this.detail,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: BrandColors.iconGradient,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: BrandColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                      color: palette.text,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Android: shows that the keyboard is on (and whether it is in use).
class _StatusCard extends StatelessWidget {
  final KeyboardStatus status;
  final BrandPalette palette;
  final bool isDark;

  const _StatusCard({
    required this.status,
    required this.palette,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      palette: palette,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: BrandListRow(
        palette: palette,
        leading: BrandIconBadge(
          icon: Icons.check_rounded,
          color: BrandColors.leaf,
          isDark: isDark,
        ),
        title: 'Bonkilingo keyboard is on',
        subtitle: status.selected
            ? 'It\'s your keyboard now. Tap Correct in any app.'
            : 'Switch to it to start correcting.',
      ),
    );
  }
}
