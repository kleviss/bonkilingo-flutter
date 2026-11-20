import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/chat_history_provider.dart';
import '../widgets/keyboard_history_sync_observer.dart';
import 'home/home_screen.dart';
import 'learn/learn_screen.dart';
import 'rewards/rewards_screen.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    return KeyboardHistorySyncObserver(
      child: _buildScaffold(context, ref, currentIndex),
    );
  }

  Widget _buildScaffold(BuildContext context, WidgetRef ref, int currentIndex) {
    return CupertinoPageScaffold(
      // Keep the tab bar pinned to the bottom of the screen when the
      // keyboard opens. Each tab's own scaffold still sees the keyboard
      // inset and pads its content, so text fields stay visible.
      resizeToAvoidBottomInset: false,
      child: Column(
        children: [
          Expanded(
            // The tab bar below already sits over the home indicator, so the
            // tabs mustn't reserve that space too: their SafeAreas would cut
            // the content off about 34pt above the tab bar.
            child: MediaQuery.removePadding(
              context: context,
              removeBottom: true,
              child: IndexedStack(
                // Tabs fill the space above the tab bar even when their
                // content is short (Home's glow background needs this).
                sizing: StackFit.expand,
                index: currentIndex,
                children: const [
                  HomeScreen(),
                  RewardsScreen(),
                  LearnScreen(),
                ],
              ),
            ),
          ),
          CupertinoTabBar(
            currentIndex: currentIndex,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.textTertiary,
            onTap: (index) {
              ref.read(navigationIndexProvider.notifier).state = index;
              // Learn's suggestions come from History, which may have grown.
              if (index == 2) ref.invalidate(chatHistoryProvider);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.card_giftcard_outlined),
                activeIcon: Icon(Icons.card_giftcard),
                label: 'Rewards',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.school_outlined),
                activeIcon: Icon(Icons.school),
                label: 'Learn',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
