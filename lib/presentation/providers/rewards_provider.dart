import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/token_reward_model.dart';
import '../../data/repositories/rewards_repository.dart';
import '../../data/data_sources/remote/rewards_api.dart';
import 'providers.dart';

/// Provider for RewardsApi
final rewardsApiProvider = Provider<RewardsApi>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return RewardsApi(dioClient);
});

/// Provider for RewardsRepository
final rewardsRepositoryProvider = Provider<RewardsRepository>((ref) {
  final rewardsApi = ref.watch(rewardsApiProvider);
  final localStorage = ref.watch(localStorageProvider);
  return RewardsRepository(rewardsApi, localStorage);
});

/// State for rewards
class RewardsState {
  final bool isLoading;
  final TokenBalanceModel? balance;
  final List<TokenRewardModel> rewardHistory;
  final List<WithdrawalRequestModel> withdrawalHistory;
  final RewardConfigModel? config;
  final String? error;
  final int? lastEarnedAmount;

  RewardsState({
    this.isLoading = false,
    this.balance,
    this.rewardHistory = const [],
    this.withdrawalHistory = const [],
    this.config,
    this.error,
    this.lastEarnedAmount,
  });

  RewardsState copyWith({
    bool? isLoading,
    TokenBalanceModel? balance,
    List<TokenRewardModel>? rewardHistory,
    List<WithdrawalRequestModel>? withdrawalHistory,
    RewardConfigModel? config,
    String? error,
    int? lastEarnedAmount,
  }) {
    return RewardsState(
      isLoading: isLoading ?? this.isLoading,
      balance: balance ?? this.balance,
      rewardHistory: rewardHistory ?? this.rewardHistory,
      withdrawalHistory: withdrawalHistory ?? this.withdrawalHistory,
      config: config ?? this.config,
      error: error,
      lastEarnedAmount: lastEarnedAmount,
    );
  }
}

/// StateNotifier for rewards
class RewardsNotifier extends StateNotifier<RewardsState> {
  final RewardsRepository _repository;

  RewardsNotifier(this._repository) : super(RewardsState());

  /// Load initial data
  Future<void> loadData() async {
    if (state.isLoading) return;
    
    state = state.copyWith(isLoading: true, error: null);

    try {
      final results = await Future.wait([
        _repository.getBalance(),
        _repository.getConfig(),
        _repository.getRewardHistory(limit: 20),
      ]);

      state = state.copyWith(
        isLoading: false,
        balance: results[0] as TokenBalanceModel,
        config: results[1] as RewardConfigModel,
        rewardHistory: results[2] as List<TokenRewardModel>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh balance only
  Future<void> refreshBalance() async {
    try {
      final balance = await _repository.getBalance(forceRefresh: true);
      state = state.copyWith(balance: balance);
    } catch (e) {
      // Silent fail - keep existing balance
    }
  }

  /// Load withdrawal history
  Future<void> loadWithdrawalHistory() async {
    try {
      final history = await _repository.getWithdrawalHistory();
      state = state.copyWith(withdrawalHistory: history);
    } catch (e) {
      // Silent fail
    }
  }

  /// Earn correction reward
  Future<bool> earnCorrectionReward(int wordCount) async {
    try {
      final result = await _repository.earnCorrectionReward(wordCount);
      if (result.success) {
        state = state.copyWith(
          lastEarnedAmount: result.amount,
        );
        await refreshBalance();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Earn lesson complete reward
  Future<bool> earnLessonCompleteReward(String lessonId) async {
    try {
      final result = await _repository.earnLessonCompleteReward(lessonId);
      if (result.success) {
        state = state.copyWith(lastEarnedAmount: result.amount);
        await refreshBalance();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Earn lesson save reward
  Future<bool> earnLessonSaveReward(String lessonId) async {
    try {
      final result = await _repository.earnLessonSaveReward(lessonId);
      if (result.success) {
        state = state.copyWith(lastEarnedAmount: result.amount);
        await refreshBalance();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Update wallet address
  Future<bool> updateWalletAddress(String address) async {
    if (!_repository.isValidSolanaAddress(address)) {
      state = state.copyWith(error: 'Invalid Solana wallet address');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _repository.updateWalletAddress(address);
      if (success) {
        await refreshBalance();
      }
      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Request withdrawal
  Future<WithdrawalResult?> requestWithdrawal(int amount) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _repository.requestWithdrawal(amount);
      await refreshBalance();
      await loadWithdrawalHistory();
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Clear last earned amount (after showing animation)
  void clearLastEarnedAmount() {
    state = state.copyWith(lastEarnedAmount: null);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for rewards state
final rewardsStateProvider = StateNotifierProvider<RewardsNotifier, RewardsState>((ref) {
  final repository = ref.watch(rewardsRepositoryProvider);
  return RewardsNotifier(repository);
});

/// Provider for just the balance (for quick access)
final tokenBalanceProvider = Provider<TokenBalanceModel?>((ref) {
  return ref.watch(rewardsStateProvider).balance;
});

/// Provider for pending balance as formatted string
final pendingBalanceStringProvider = Provider<String>((ref) {
  final balance = ref.watch(tokenBalanceProvider);
  if (balance == null) return '0';
  return _formatBalance(balance.pendingBalance);
});

/// Format balance with commas
String _formatBalance(int amount) {
  if (amount < 1000) return amount.toString();
  if (amount < 1000000) {
    return '${(amount / 1000).toStringAsFixed(1)}K';
  }
  return '${(amount / 1000000).toStringAsFixed(2)}M';
}

