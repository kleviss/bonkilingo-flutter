import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/rewards_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/brand/brand_surfaces.dart';
import '../../widgets/brand/glow_background.dart';
import '../../widgets/brand/highlighted_title.dart';
import '../../widgets/cupertino_app_bar.dart';

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
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final p = BrandPalette(isDark);

    final balance = rewardsState.balance;
    final pendingBalance = balance?.pendingBalance ?? 0;

    return GlowBackground(
      isDark: isDark,
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0x00000000),
        navigationBar:
            const CupertinoAppBar(title: 'Rewards', transparent: true),
        child: SafeArea(
          child: rewardsState.isLoading && balance == null
              ? const Center(child: CupertinoActivityIndicator())
              : CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    CupertinoSliverRefreshControl(
                      onRefresh: () async {
                        await ref
                            .read(rewardsStateProvider.notifier)
                            .loadData();
                      },
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          HighlightedTitle(
                            'Earn *BONK*',
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
                            'For every correction, lesson and day of your streak.',
                            style: TextStyle(fontSize: 16, color: p.muted),
                          ),
                          const SizedBox(height: 20),
                          _buildBalanceCard(p, pendingBalance, balance),
                          const SizedBox(height: 12),
                          _buildWalletSection(p, balance),
                          const SizedBox(height: 32),
                          _buildHowToEarnSection(p, rewardsState.config),
                          const SizedBox(height: 32),
                          _buildRecentActivitySection(
                            p,
                            rewardsState.rewardHistory,
                          ),
                          if (rewardsState.withdrawalHistory.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            _buildWithdrawalHistorySection(
                              p,
                              rewardsState.withdrawalHistory,
                            ),
                          ],
                        ]),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
      BrandPalette p, int pendingBalance, dynamic balance) {
    const inkSoft = Color(0xB31C1C1E);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        gradient: BrandColors.iconGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: BrandColors.tangerine.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Your BONK balance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: inkSoft,
                ),
              ),
              const Spacer(),
              if (balance != null && balance.withdrawalsEnabled)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: BrandColors.ink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 14, color: BrandColors.ink),
                      SizedBox(width: 4),
                      Text(
                        'Withdrawals on',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: BrandColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    pendingBalance.formatted.isEmpty
                        ? '0'
                        : pendingBalance.formatted,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      height: 1.05,
                      color: BrandColors.ink,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 8),
                child: Text(
                  'BONK',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: BrandColors.ink,
                  ),
                ),
              ),
            ],
          ),
          if (balance != null) ...[
            const SizedBox(height: 16),
            Container(
                height: 1, color: BrandColors.ink.withValues(alpha: 0.12)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _BalanceStat(
                    label: 'Total earned',
                    value: balance.totalEarned.formatted,
                    icon: Icons.trending_up,
                  ),
                ),
                Expanded(
                  child: _BalanceStat(
                    label: 'Withdrawn',
                    value: balance.totalWithdrawn.formatted,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWalletSection(BrandPalette p, dynamic balance) {
    final hasWallet = balance?.walletAddress != null;
    final canWithdraw = balance?.canWithdraw ?? false;

    return BrandCard(
      palette: p,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BrandIconBadge(
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFFB07CF5),
                isDark: p.isDark,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solana wallet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: p.text,
                      ),
                    ),
                    Text(
                      hasWallet
                          ? 'Withdraw BONK to this address'
                          : 'Connect a wallet to withdraw your BONK',
                      style: TextStyle(fontSize: 13, color: p.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasWallet) ...[
            Container(
              padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
              decoration: BoxDecoration(
                color: p.cardSunken,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _truncateAddress(balance.walletAddress),
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Menlo',
                        color: p.text,
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 40,
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: balance.walletAddress),
                      );
                      _showToast('Wallet address copied');
                    },
                    child: Semantics(
                      label: 'Copy wallet address',
                      child: Icon(Icons.copy, size: 18, color: p.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    onPressed: () => _showEditWalletDialog(),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.cardSunken,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: p.text,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SecondaryPillButton(
                    palette: p,
                    label: 'Withdraw',
                    icon: Icons.north_east,
                    onPressed: canWithdraw ? () => _showWithdrawDialog() : null,
                  ),
                ),
              ],
            ),
            if (!canWithdraw && balance != null) ...[
              const SizedBox(height: 10),
              Text(
                'You can withdraw from ${balance.minWithdrawal.formatted} BONK.',
                style: TextStyle(fontSize: 13, color: p.muted),
              ),
            ],
          ] else
            SizedBox(
              width: double.infinity,
              child: SecondaryPillButton(
                palette: p,
                label: 'Connect wallet',
                icon: Icons.link,
                onPressed: () => _showAddWalletDialog(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHowToEarnSection(BrandPalette p, dynamic config) {
    final earnMethods = [
      (
        Icons.spellcheck,
        BrandColors.tangerine,
        'Text corrections',
        'For every text you correct',
        '100–500',
      ),
      (
        Icons.school_outlined,
        BrandColors.leaf,
        'Complete lessons',
        'Finish an AI-made lesson',
        '${config?.lessonComplete ?? 200}',
      ),
      (
        Icons.local_fire_department,
        BrandColors.ribbon,
        'Daily streak',
        'Learn something every day',
        '${config?.dailyStreakBonus ?? 150}',
      ),
      (
        Icons.group_add_outlined,
        const Color(0xFF4F8EF7),
        'Invite friends',
        'When a friend joins',
        '${config?.referralBonus ?? 5000}',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandSectionTitle('How to earn', palette: p),
        BrandCard(
          palette: p,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < earnMethods.length; i++) ...[
                if (i > 0) BrandRowDivider(palette: p),
                BrandListRow(
                  palette: p,
                  leading: BrandIconBadge(
                    icon: earnMethods[i].$1,
                    color: earnMethods[i].$2,
                    isDark: p.isDark,
                  ),
                  title: earnMethods[i].$3,
                  subtitle: earnMethods[i].$4,
                  trailing: _BonkAmount(
                    amount: '+${earnMethods[i].$5}',
                    palette: p,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection(BrandPalette p, List rewardHistory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandSectionTitle('Recent activity', palette: p),
        if (rewardHistory.isEmpty)
          BrandCard(
            palette: p,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                BrandIconBadge(
                  icon: Icons.star_rounded,
                  color: BrandColors.tangerine,
                  isDark: p.isDark,
                  size: 52,
                ),
                const SizedBox(height: 12),
                Text(
                  'No BONK yet',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Correct your first sentence on Home to start earning.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: p.muted),
                ),
              ],
            ),
          )
        else
          BrandCard(
            palette: p,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final (i, reward) in rewardHistory.take(5).indexed) ...[
                  if (i > 0) BrandRowDivider(palette: p),
                  BrandListRow(
                    palette: p,
                    leading: BrandIconBadge(
                      icon: Icons.add,
                      color: BrandPalette.green,
                      isDark: p.isDark,
                    ),
                    title: reward.readableReason,
                    subtitle: _formatTimeAgo(reward.createdAt),
                    trailing: _BonkAmount(
                      amount: '+${reward.amount}',
                      palette: p,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWithdrawalHistorySection(BrandPalette p, List withdrawals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrandSectionTitle('Withdrawals', palette: p),
        BrandCard(
          palette: p,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (final (i, w) in withdrawals.take(5).indexed) ...[
                if (i > 0) BrandRowDivider(palette: p),
                BrandListRow(
                  palette: p,
                  leading: BrandIconBadge(
                    icon: w.isCompleted
                        ? Icons.check_circle_outline
                        : w.isFailed
                            ? Icons.error_outline
                            : Icons.schedule,
                    color: w.isCompleted
                        ? BrandPalette.green
                        : w.isFailed
                            ? BrandPalette.red
                            : BrandColors.tangerine,
                    isDark: p.isDark,
                  ),
                  title: '${w.amount.formatted} BONK',
                  subtitle: _statusLabel(w.status as String),
                  onTap: w.txSignature != null
                      ? () => _openExplorer(w.explorerUrl)
                      : null,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return status;
    return status[0].toUpperCase() + status.substring(1).toLowerCase();
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

class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _BalanceStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xB31C1C1E)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value.isEmpty ? '0' : value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: BrandColors.ink,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xB31C1C1E)),
            ),
          ],
        ),
      ],
    );
  }
}

class _BonkAmount extends StatelessWidget {
  final String amount;
  final BrandPalette palette;

  const _BonkAmount({required this.amount, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: palette.greenBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        amount,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: BrandPalette.green,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
