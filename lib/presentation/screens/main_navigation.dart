import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'home/home_screen.dart';
import 'learn/learn_screen.dart';
import 'rewards/rewards_screen.dart';

final navigationIndexProvider = StateProvider<int>((ref) => 0);

class MainNavigation extends ConsumerWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(navigationIndexProvider);

    return CupertinoPageScaffold(
      child: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: const [
                HomeScreen(),
                RewardsScreen(),
                LearnScreen(),
              ],
            ),
          ),
          CupertinoTabBar(
            currentIndex: currentIndex,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.textTertiary,
            onTap: (index) {
              ref.read(navigationIndexProvider.notifier).state = index;
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

