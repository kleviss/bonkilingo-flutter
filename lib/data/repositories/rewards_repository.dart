import '../data_sources/remote/rewards_api.dart';
import '../data_sources/local/local_storage.dart';
import '../models/token_reward_model.dart';

/// Repository for managing token rewards
class RewardsRepository {
  final RewardsApi _rewardsApi;
  // ignore: unused_field - reserved for future offline caching
  final AppLocalStorage _localStorage;
  
  // Cache
  TokenBalanceModel? _cachedBalance;
  RewardConfigModel? _cachedConfig;
  DateTime? _balanceLastFetched;
  
  static const _balanceCacheDuration = Duration(seconds: 30);

  RewardsRepository(this._rewardsApi, this._localStorage);

  /// Get user's token balance
  Future<TokenBalanceModel> getBalance({bool forceRefresh = false}) async {
    final now = DateTime.now();
    
    // Return cached if fresh
    if (!forceRefresh && 
        _cachedBalance != null && 
        _balanceLastFetched != null &&
        now.difference(_balanceLastFetched!) < _balanceCacheDuration) {
      return _cachedBalance!;
    }

    try {
      _cachedBalance = await _rewardsApi.getBalance();
      _balanceLastFetched = now;
      return _cachedBalance!;
    } catch (e) {
      // Return cached on error if available
      if (_cachedBalance != null) {
        return _cachedBalance!;
      }
      rethrow;
    }
  }

  /// Get reward history
  Future<List<TokenRewardModel>> getRewardHistory({int limit = 50}) async {
    return _rewardsApi.getRewardHistory(limit: limit);
  }

  /// Get reward configuration
  Future<RewardConfigModel> getConfig() async {
    if (_cachedConfig != null) {
      return _cachedConfig!;
    }
    _cachedConfig = await _rewardsApi.getConfig();
    return _cachedConfig!;
  }

  /// Record a correction reward
  Future<EarnRewardResult> earnCorrectionReward(int wordCount) async {
    final result = await _rewardsApi.earnReward(
      reason: 'correction',
      metadata: {'wordCount': wordCount},
    );
    
    // Invalidate cache
    _balanceLastFetched = null;
    
    return result;
  }

  /// Record a lesson completion reward
  Future<EarnRewardResult> earnLessonCompleteReward(String lessonId) async {
    final result = await _rewardsApi.earnReward(
      reason: 'lesson_complete',
      metadata: {'lessonId': lessonId},
    );
    
    _balanceLastFetched = null;
    return result;
  }

  /// Record a lesson save reward
  Future<EarnRewardResult> earnLessonSaveReward(String lessonId) async {
    final result = await _rewardsApi.earnReward(
      reason: 'lesson_save',
      metadata: {'lessonId': lessonId},
    );
    
    _balanceLastFetched = null;
    return result;
  }

  /// Record daily streak reward
  Future<EarnRewardResult> earnDailyStreakReward(int streakDays) async {
    final result = await _rewardsApi.earnReward(
      reason: 'daily_streak',
      metadata: {'streakDays': streakDays},
    );
    
    _balanceLastFetched = null;
    return result;
  }

  /// Update user's wallet address
  Future<bool> updateWalletAddress(String walletAddress) async {
    final success = await _rewardsApi.updateWalletAddress(walletAddress);
    if (success) {
      _balanceLastFetched = null; // Invalidate cache
    }
    return success;
  }

  /// Request withdrawal
  Future<WithdrawalResult> requestWithdrawal(int amount) async {
    final result = await _rewardsApi.requestWithdrawal(amount);
    if (result.success) {
      _balanceLastFetched = null; // Invalidate cache
    }
    return result;
  }

  /// Get withdrawal history
  Future<List<WithdrawalRequestModel>> getWithdrawalHistory({int limit = 20}) async {
    return _rewardsApi.getWithdrawalHistory(limit: limit);
  }

  /// Get system status
  Future<RewardsSystemStatus> getSystemStatus() async {
    return _rewardsApi.getSystemStatus();
  }

  /// Validate Solana wallet address format
  bool isValidSolanaAddress(String address) {
    // Solana addresses are base58 encoded and 32-44 characters
    if (address.length < 32 || address.length > 44) {
      return false;
    }
    
    // Check for valid base58 characters
    final base58Chars = RegExp(r'^[1-9A-HJ-NP-Za-km-z]+$');
    return base58Chars.hasMatch(address);
  }

  /// Clear cache
  void clearCache() {
    _cachedBalance = null;
    _cachedConfig = null;
    _balanceLastFetched = null;
  }
}

