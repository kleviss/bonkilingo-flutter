import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_helper.dart';
import '../../../core/constants/language_constants.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/brand/glow_background.dart';
import '../../widgets/brand/highlighted_title.dart';
import '../../widgets/brand/pill_button.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/cupertino_app_bar.dart';
import '../../widgets/cupertino_correction_card.dart';
import '../history/history_screen.dart';
import 'home_provider.dart';
import '../../widgets/brand/fade_top_edge.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _textController = TextEditingController();
  final _inputFocus = FocusNode();
  String _inputText = '';

  @override
  void dispose() {
    _textController.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = ThemeHelper(themeMode);
    final isDark = themeMode == ThemeMode.dark;
    final p = BrandPalette(isDark);
    final isSignedIn = ref.watch(currentUserProvider).value != null;
    final profile = ref.watch(userProfileStateProvider).profile;
    final languageLocked =
        homeState.autoDetect && homeState.detectedLanguage != null;

    return GlowBackground(
      isDark: isDark,
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0x00000000),
        navigationBar:
            const CupertinoAppBar(title: 'Bonkilingo', transparent: true),
        child: FadeTopEdge(
          child: SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Headline
                  HighlightedTitle(
                    'What will you *write* today?',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.15,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bonkilingo fixes it and tells you why.',
                    style: TextStyle(fontSize: 16, color: p.muted),
                  ),

                  if (isSignedIn) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatPill(
                          palette: p,
                          icon: Icons.local_fire_department,
                          iconColor: BrandColors.tangerine,
                          label: '${profile?.streakDays ?? 0} day streak',
                        ),
                        const SizedBox(width: 8),
                        _StatPill(
                          palette: p,
                          icon: Icons.star_rounded,
                          iconColor: BrandColors.sunny,
                          label: '${(profile?.bonkPoints ?? 0).formatted} BONK',
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Composer
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: p.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          // The chip takes its natural width; with a Spacer
                          // next to a Flexible the two split the free space
                          // and "English" was cut to "E…".
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Language chip
                            Flexible(
                              child: CupertinoButton(
                                padding: EdgeInsets.zero,
                                minSize: 36,
                                onPressed: languageLocked
                                    ? null
                                    : () => _showLanguagePicker(context, theme),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: p.cardSunken,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.translate,
                                        size: 16,
                                        color: p.muted,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          _getLanguageName(
                                            homeState.detectedLanguage ??
                                                homeState.selectedLanguage,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: p.text,
                                          ),
                                        ),
                                      ),
                                      if (!languageLocked) ...[
                                        const SizedBox(width: 2),
                                        Icon(
                                          Icons.unfold_more,
                                          size: 16,
                                          color: p.muted,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 12),
                                Text(
                                  'Auto-detect',
                                  style:
                                      TextStyle(fontSize: 13, color: p.muted),
                                ),
                                const SizedBox(width: 4),
                                Transform.scale(
                                  scale: 0.8,
                                  child: CupertinoSwitch(
                                    value: homeState.autoDetect,
                                    onChanged: (_) => ref
                                        .read(homeStateProvider.notifier)
                                        .toggleAutoDetect(),
                                    activeTrackColor: BrandColors.tangerine,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Detection status
                        if (homeState.autoDetect && homeState.isDetecting)
                          _StatusLine(
                            palette: p,
                            leading:
                                const CupertinoActivityIndicator(radius: 6),
                            text: 'Detecting language…',
                          ),
                        if (homeState.autoDetect &&
                            homeState.detectedLanguage != null &&
                            !homeState.isDetecting)
                          _StatusLine(
                            palette: p,
                            leading: const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: BrandPalette.green,
                            ),
                            text:
                                'Detected ${_getLanguageName(homeState.detectedLanguage!)}',
                          ),

                        // Text input
                        // Keyed with an owned focus node: the status lines
                        // above appear while typing, and without a key the
                        // field is rebuilt and drops focus mid-sentence.
                        CupertinoTextField(
                          key: const ValueKey('composer-input'),
                          focusNode: _inputFocus,
                          controller: _textController,
                          placeholder: 'Type or paste a sentence…',
                          minLines: 4,
                          maxLines: 10,
                          padding: const EdgeInsets.only(top: 12, bottom: 4),
                          decoration: null,
                          style: TextStyle(
                            color: p.text,
                            fontSize: 18,
                            height: 1.4,
                          ),
                          placeholderStyle: TextStyle(
                            color: p.muted,
                            fontSize: 18,
                            height: 1.4,
                          ),
                          cursorColor: BrandColors.tangerine,
                          onChanged: (text) {
                            setState(() {
                              _inputText = text;
                            });
                            ref
                                .read(homeStateProvider.notifier)
                                .onTextChanged(text);
                          },
                        ),

                        // Clear
                        if (_inputText.isNotEmpty)
                          Align(
                            alignment: Alignment.centerRight,
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              minSize: 32,
                              onPressed: () {
                                _textController.clear();
                                setState(() => _inputText = '');
                                ref
                                    .read(homeStateProvider.notifier)
                                    .onTextChanged('');
                              },
                              child: Text(
                                'Clear',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: p.muted,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Correct
                  PillButton(
                    label: 'Correct',
                    loading: homeState.isLoading,
                    onPressed: _inputText.trim().isEmpty
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();
                            ref
                                .read(homeStateProvider.notifier)
                                .correctText(_inputText);
                          },
                  ),

                  if (homeState.error != null && !homeState.isLoading) ...[
                    const SizedBox(height: 12),
                    Text(
                      homeState.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: BrandPalette.red,
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Corrections
                  Row(
                    children: [
                      Text(
                        'Corrections',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: p.text,
                        ),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        minSize: 32,
                        onPressed: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => const HistoryScreen(),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              'History',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: p.text,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: p.muted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (homeState.correctedText != null)
                    CupertinoCorrectionCard(
                      correctedText: homeState.correctedText!,
                      inputText: _inputText,
                    )
                  else ...[
                    // Show what a result looks like until there is one.
                    const Opacity(
                      opacity: 0.75,
                      child: CupertinoCorrectionCard(
                        inputText: 'I goed to the store yesterday.',
                        correctedText: 'I went to the store yesterday.',
                        example: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your corrections will show up here, like this example.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: p.muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, ThemeHelper theme) {
    final homeNotifier = ref.read(homeStateProvider.notifier);
    final currentLanguage = ref.read(homeStateProvider).selectedLanguage;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.border, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: theme.primary),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    'Select Language',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
                    ),
                  ),
                  CupertinoButton(
                    child: Text(
                      'Done',
                      style: TextStyle(color: theme.primary),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                backgroundColor: theme.cardBackground,
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: LanguageConstants.supportedLanguages.indexWhere(
                    (lang) => lang.code == currentLanguage,
                  ),
                ),
                onSelectedItemChanged: (index) {
                  homeNotifier.selectLanguage(
                    LanguageConstants.supportedLanguages[index].code,
                  );
                },
                children: LanguageConstants.supportedLanguages
                    .map((lang) => Center(
                          child: Text(
                            lang.name,
                            style: TextStyle(color: theme.textPrimary),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    return LanguageConstants.supportedLanguages
        .firstWhere(
          (lang) => lang.code == code,
          orElse: () => const Language(code: '', name: 'Unknown'),
        )
        .name;
  }
}

class _StatPill extends StatelessWidget {
  final BrandPalette palette;
  final IconData icon;
  final Color iconColor;
  final String label;

  const _StatPill({
    required this.palette,
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(999),
        boxShadow: palette.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final BrandPalette palette;
  final Widget leading;
  final String text;

  const _StatusLine({
    required this.palette,
    required this.leading,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          SizedBox(width: 14, height: 14, child: Center(child: leading)),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 13, color: palette.muted)),
        ],
      ),
    );
  }
}
