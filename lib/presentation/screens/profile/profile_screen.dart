import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import '../history/history_screen.dart';
import '../../widgets/brand/brand_page.dart';
import '../../widgets/brand/brand_surfaces.dart';
import '../../widgets/brand/pill_button.dart';
import '../settings/settings_screen.dart';

const _blue = Color(0xFF4F8EF7);
const _purple = Color(0xFFB07CF5);

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final userProfileState = ref.watch(userProfileStateProvider);
    final profile = userProfileState.profile;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final p = BrandPalette(isDark);
    final isSignedIn = currentUser != null;

    return BrandPage(
      isDark: isDark,
      title: 'My account',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile header
            BrandCard(
              palette: p,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: BrandColors.iconGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: BrandColors.tangerine.withValues(alpha: 0.3),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      // Guests (and accounts without an email) get a person
                      // icon rather than a made-up initial.
                      child: (currentUser?.email?.isNotEmpty ?? false)
                          ? Text(
                              currentUser!.email!.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: BrandColors.ink,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 44,
                              color: BrandColors.ink,
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    currentUser?.email ?? 'Guest',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: p.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (isSignedIn)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: BrandColors.sunny.withValues(
                          alpha: isDark ? 0.22 : 0.35,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Level ${profile?.level ?? 1}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: p.text,
                        ),
                      ),
                    )
                  else ...[
                    Text(
                      'Sign in to save your corrections and earn BONK points.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: p.muted),
                    ),
                    const SizedBox(height: 16),
                    PillButton(
                      label: 'Sign in',
                      onPressed: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (isSignedIn) ...[
              // Stats grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      palette: p,
                      title: 'BONK points',
                      value: (profile?.bonkPoints ?? 0).formatted,
                      icon: Icons.star_rounded,
                      color: BrandColors.tangerine,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      palette: p,
                      title: 'Corrections',
                      value: (profile?.totalCorrections ?? 0).toString(),
                      icon: Icons.check_circle_outline,
                      color: BrandColors.leaf,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      palette: p,
                      title: 'Streak',
                      value: '${profile?.streakDays ?? 0} days',
                      icon: Icons.local_fire_department,
                      color: BrandColors.ribbon,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      palette: p,
                      title: 'Languages',
                      value: (profile?.languagesLearned.length ?? 0).toString(),
                      icon: Icons.language,
                      color: _blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Languages learning
              if (profile != null && profile.languagesLearned.isNotEmpty) ...[
                BrandSectionTitle('Languages learning', palette: p),
                BrandCard(
                  palette: p,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.languagesLearned.map((lang) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: p.cardSunken,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          lang.capitalize(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: p.text,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ],

            // History & settings
            BrandCard(
              palette: p,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  BrandListRow(
                    palette: p,
                    leading: BrandIconBadge(
                      icon: Icons.history,
                      color: BrandColors.tangerine,
                      isDark: isDark,
                    ),
                    title: 'History',
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => const HistoryScreen(),
                      ),
                    ),
                  ),
                  BrandRowDivider(palette: p),
                  BrandListRow(
                    palette: p,
                    leading: BrandIconBadge(
                      icon: Icons.settings_outlined,
                      color: _purple,
                      isDark: isDark,
                    ),
                    title: 'Settings',
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Sign out
            if (isSignedIn) ...[
              const SizedBox(height: 24),
              _DestructivePill(
                palette: p,
                icon: Icons.logout,
                label: 'Sign out',
                onPressed: () async {
                  final confirm = await showCupertinoDialog<bool>(
                    context: context,
                    builder: (context) => CupertinoAlertDialog(
                      title: const Text('Sign out'),
                      content: const Text('Are you sure you want to sign out?'),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    await ref.read(authStateProvider.notifier).signOut();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small stat tile: coloured icon badge, value and label.
class _StatCard extends StatelessWidget {
  final BrandPalette palette;
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.palette,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return BrandCard(
      palette: palette,
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Row(
        children: [
          BrandIconBadge(
            icon: icon,
            color: color,
            isDark: palette.isDark,
            size: 38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: palette.text,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: palette.muted),
                ),
              ],
            ),
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
