import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, RefreshIndicator;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_helper.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/rewards_provider.dart';
import '../../providers/theme_provider.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  @override
  void initState() {
    super.initState();
    // Load rewards data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rewardsStateProvider.notifier).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rewardsState = ref.watch(rewardsStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final theme = ThemeHelper(themeMode);

    final balance = rewardsState.balance;
    final pendingBalance = balance?.pendingBalance ?? 0;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('BONK Rewards'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(Icons.refresh),
          onPressed: () {
            ref.read(rewardsStateProvider.notifier).loadData();
          },
        ),
      ),
      child: SafeArea(
        child: rewardsState.isLoading && balance == null
            ? const Center(child: CupertinoActivityIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  await ref.read(rewardsStateProvider.notifier).loadData();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // BONK Balance Card
                      _buildBalanceCard(theme, pendingBalance, balance),

                      const SizedBox(height: 16),

                      // Wallet & Withdraw Section
                      _buildWalletSection(theme, balance),

                      const SizedBox(height: 24),

                      // Stats Row
                      if (balance != null) _buildStatsRow(theme, balance),

                      const SizedBox(height: 24),

                      // How to Earn Section
                      _buildHowToEarnSection(theme, rewardsState.config),

                      const SizedBox(height: 24),

                      // Recent Activity
                      _buildRecentActivitySection(theme, rewardsState.rewardHistory),

                      const SizedBox(height: 24),

                      // Withdrawal History
                      if (rewardsState.withdrawalHistory.isNotEmpty)
                        _buildWithdrawalHistorySection(theme, rewardsState.withdrawalHistory),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBalanceCard(ThemeHelper theme, int pendingBalance, dynamic balance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🐕',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              const Text(
                'Your BONK Balance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            pendingBalance.formatted,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'BONK TOKENS',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
          if (balance != null && balance.withdrawalsEnabled) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 14,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Withdrawals Enabled',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWalletSection(ThemeHelper theme, dynamic balance) {
    final hasWallet = balance?.walletAddress != null;
    final canWithdraw = balance?.canWithdraw ?? false;

    return Container(
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
            children: [
              Icon(Icons.account_balance_wallet, color: theme.textPrimary),
              const SizedBox(width: 8),
              Text(
                'Solana Wallet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasWallet) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.backgroundTertiary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _truncateAddress(balance.walletAddress),
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        color: theme.textSecondary,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 32,
                    child: Icon(Icons.copy, size: 18, color: theme.textSecondary),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: balance.walletAddress));
                      _showToast('Wallet address copied');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: theme.backgroundTertiary,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: () => _showEditWalletDialog(),
                    child: Text(
                      'Change Wallet',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: canWithdraw ? AppColors.success : AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(8),
                    onPressed: canWithdraw ? () => _showWithdrawDialog() : null,
                    child: const Text(
                      'Withdraw',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (!canWithdraw && balance != null) ...[
              const SizedBox(height: 8),
              Text(
                'Minimum withdrawal: ${balance.minWithdrawal.formatted} BONK',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTertiary,
                ),
              ),
            ],
          ] else ...[
            Text(
              'Connect your Solana wallet to withdraw BONK tokens',
              style: TextStyle(
                fontSize: 14,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
                onPressed: () => _showAddWalletDialog(),
                child: const Text(
                  'Connect Wallet',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeHelper theme, dynamic balance) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Earned',
            value: balance.totalEarned.formatted,
            icon: Icons.trending_up,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Withdrawn',
            value: balance.totalWithdrawn.formatted,
            icon: Icons.account_balance,
            color: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildHowToEarnSection(ThemeHelper theme, dynamic config) {
    final earnMethods = [
      {
        'icon': Icons.spellcheck,
        'title': 'Text Corrections',
        'desc': 'Earn BONK for every text you correct',
        'amount': '100-500',
      },
      {
        'icon': Icons.school,
        'title': 'Complete Lessons',
        'desc': 'Finish AI-generated lessons',
        'amount': '${config?.lessonComplete ?? 200}',
      },
      {
        'icon': Icons.local_fire_department,
        'title': 'Daily Streak',
        'desc': 'Keep your learning streak going',
        'amount': '${config?.dailyStreakBonus ?? 150}',
      },
      {
        'icon': Icons.group_add,
        'title': 'Refer Friends',
        'desc': 'Invite friends to earn bonus',
        'amount': '${config?.referralBonus ?? 5000}',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to Earn',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...earnMethods.map((method) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      method['icon'] as IconData,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method['title'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                          ),
                        ),
                        Text(
                          method['desc'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${method['amount']}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildRecentActivitySection(ThemeHelper theme, List rewardHistory) {
    if (rewardHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.border),
        ),
        child: Column(
          children: [
            Icon(Icons.history, size: 48, color: theme.textTertiary),
            const SizedBox(height: 12),
            Text(
              'No rewards yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start learning to earn BONK tokens!',
              style: TextStyle(
                fontSize: 14,
                color: theme.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...rewardHistory.take(5).map((reward) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
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
                      Icons.add,
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
                          '+${reward.amount} BONK',
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          reward.readableReason,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatTimeAgo(reward.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.textTertiary,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildWithdrawalHistorySection(ThemeHelper theme, List withdrawals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Withdrawal History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...withdrawals.take(5).map((w) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.border),
              ),
              child: Row(
                children: [
                  Icon(
                    w.isCompleted
                        ? Icons.check_circle
                        : w.isFailed
                            ? Icons.error
                            : Icons.pending,
                    color: w.isCompleted
                        ? AppColors.success
                        : w.isFailed
                            ? AppColors.error
                            : AppColors.warning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${w.amount.formatted} BONK',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.textPrimary,
                          ),
                        ),
                        Text(
                          w.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (w.txSignature != null)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 32,
                      child: const Icon(Icons.open_in_new, size: 18),
                      onPressed: () => _openExplorer(w.explorerUrl),
                    ),
                ],
              ),
            )),
      ],
    );
  }

  // ========== Dialogs ==========

  void _showAddWalletDialog() {
    final controller = TextEditingController();

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Connect Solana Wallet'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              const Text(
                'Enter your Solana wallet address to receive BONK tokens.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: controller,
                placeholder: 'Solana wallet address',
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
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
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await ref
                  .read(rewardsStateProvider.notifier)
                  .updateWalletAddress(controller.text.trim());
              if (success) {
                _showToast('Wallet connected successfully!');
              } else {
                _showToast('Failed to connect wallet');
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showEditWalletDialog() {
    _showAddWalletDialog();
  }

  void _showWithdrawDialog() {
    final balance = ref.read(rewardsStateProvider).balance;
    if (balance == null) return;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Withdraw BONK'),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Text(
                'Withdraw ${balance.pendingBalance.formatted} BONK to your wallet?',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                _truncateAddress(balance.walletAddress ?? ''),
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: CupertinoColors.systemGrey,
                ),
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
            onPressed: () async {
              Navigator.of(context).pop();
              final result = await ref
                  .read(rewardsStateProvider.notifier)
                  .requestWithdrawal(balance.pendingBalance);
              if (result != null && result.success) {
                _showToast('Withdrawal requested! Processing...');
              } else {
                _showToast('Withdrawal failed');
              }
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }

  // ========== Helpers ==========

  String _truncateAddress(String address) {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${diff.inDays ~/ 7}w ago';
  }

  void _showToast(String message) {
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

  Future<void> _openExplorer(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _StatCard extends ConsumerWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = ThemeHelper(themeMode);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
