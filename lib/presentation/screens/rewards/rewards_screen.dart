import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_helper.dart';
import '../../../core/utils/extensions.dart';
import '../../widgets/cupertino_app_bar.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileState = ref.watch(userProfileStateProvider);
    final profile = userProfileState.profile;
    final themeMode = ref.watch(themeModeProvider);
    final theme = ThemeHelper(themeMode);

    final bonkPoints = profile?.bonkPoints ?? 0;

    final rewards = [
      RewardItem(
        id: 1,
        title: 'Premium Feature',
        description: 'Unlock all premium features for a month',
        cost: 500,
        icon: Icons.star,
      ),
      RewardItem(
        id: 2,
        title: 'Exclusive Language',
        description: 'Access exclusive language learning exercises',
        cost: 300,
        icon: Icons.book,
      ),
      RewardItem(
        id: 3,
        title: 'Cosmetic App Upgrades',
        description: 'Customize your app with unique themes',
        cost: 200,
        icon: Icons.palette,
      ),
    ];

    final bonkActivity = [
      ActivityItem(
        id: '1',
        amount: 100,
        description: 'Completed daily challenge',
        type: 'challenge',
      ),
      ActivityItem(
        id: '2',
        amount: 50,
        description: 'Corrected 50 sentences',
        type: 'milestone',
      ),
      ActivityItem(
        id: '3',
        amount: 200,
        description: 'Streak bonus',
        type: 'streak',
      ),
    ];

    return CupertinoPageScaffold(
      navigationBar: const CupertinoAppBar(title: 'Rewards'),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // BONK Balance Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your BONK Balance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bonkPoints.formatted,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'BONK POINTS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Next Reward Progress
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Next Reward',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${200 - (bonkPoints % 200)} BONK to go',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundTertiary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: (bonkPoints % 200) / 200,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Available Rewards
              const Text(
                'Available Rewards',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label, // Adapts to theme
                ),
              ),
              const SizedBox(height: 16),

              ...rewards.map((reward) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.backgroundTertiary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            reward.icon,
                            color: theme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reward.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reward.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${reward.cost} BONK',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          color: bonkPoints >= reward.cost
                              ? AppColors.primary
                              : AppColors.textTertiary,
                          borderRadius: BorderRadius.circular(8),
                          minSize: 36,
                          onPressed: bonkPoints >= reward.cost
                              ? () => _showRedeemDialog(context, reward)
                              : null,
                          child: const Text(
                            'Redeem',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )),

              const SizedBox(height: 32),

              // BONK Activity
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 16),

              ...bonkActivity.map((activity) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.successLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '+${activity.amount} BONK',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                activity.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _showRedeemDialog(BuildContext context, RewardItem reward) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Redeem Reward'),
        content: Text(
          'Redeem "${reward.title}" for ${reward.cost} BONK points?',
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
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('Success!'),
                  content: const Text('Reward redeemed successfully!'),
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
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }
}

class RewardItem {
  final int id;
  final String title;
  final String description;
  final int cost;
  final IconData icon;

  RewardItem({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.icon,
  });
}

class ActivityItem {
  final String id;
  final int amount;
  final String description;
  final String type;

  ActivityItem({
    required this.id,
    required this.amount,
    required this.description,
    required this.type,
  });
}
