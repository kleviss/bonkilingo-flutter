import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_helper.dart';
import '../../core/utils/extensions.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../screens/profile/profile_screen.dart';

class CupertinoAppBar extends ConsumerWidget
    implements ObstructingPreferredSizeWidget {
  final String title;
  final Widget? leading;

  /// No bar background or hairline, for screens with a [GlowBackground].
  final bool transparent;

  const CupertinoAppBar({
    super.key,
    required this.title,
    this.leading,
    this.transparent = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CupertinoNavigationBar(
      // Used by tab roots that MainNavigation keeps alive together in an
      // IndexedStack. With the default hero tag, every push from a tab hits
      // "multiple heroes that share the same tag".
      transitionBetweenRoutes: false,
      backgroundColor: transparent ? const Color(0x00000000) : null,
      // A clear background makes iOS guess "dark" for the status bar; use
      // the app's theme instead so light mode gets dark status icons.
      brightness: transparent ? CupertinoTheme.brightnessOf(context) : null,
      border: transparent
          ? null
          : const Border(
              bottom: BorderSide(color: Color(0x4D000000), width: 0),
            ),
      // Show title on the left like web app
      leading: leading ??
          Padding(
            padding: const EdgeInsets.only(left: 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      // No middle widget - title is in leading
      middle: null,
      trailing: const AccountChip(),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  bool shouldFullyObstruct(BuildContext context) => true;
}

/// Avatar + BONK points pill. Opens the account screen, which is also where
/// guests sign in and everyone reaches History and Settings.
class AccountChip extends ConsumerWidget {
  const AccountChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    final profile = ref.watch(userProfileStateProvider).profile;
    final theme = ThemeHelper(ref.watch(themeModeProvider));
    final isSignedIn = currentUser != null;
    final initial = currentUser?.email?.isNotEmpty == true
        ? currentUser!.email!.substring(0, 1).toUpperCase()
        : null;

    return Semantics(
      button: true,
      label: isSignedIn ? 'My account' : 'Account, not signed in',
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 44,
        onPressed: () {
          Navigator.of(context, rootNavigator: true).push(
            CupertinoPageRoute(builder: (context) => const ProfileScreen()),
          );
        },
        child: Container(
          height: 34,
          padding: const EdgeInsets.fromLTRB(3, 3, 12, 3),
          decoration: BoxDecoration(
            color: theme.backgroundTertiary,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: theme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSignedIn ? AppColors.primary : theme.border,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: initial != null
                    ? Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.black,
                        ),
                      )
                    : Icon(Icons.person, size: 18, color: theme.textSecondary),
              ),
              const SizedBox(width: 8),
              if (isSignedIn) ...[
                const Icon(Icons.star, size: 14, color: AppColors.primary),
                const SizedBox(width: 3),
                Text(
                  (profile?.bonkPoints ?? 0).formatted,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
              ] else
                Text(
                  'Guest',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
