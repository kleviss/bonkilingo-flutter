import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../models/token_reward_model.dart';

/// API client for rewards endpoints
class RewardsApi {
  final DioClient _dioClient;

  RewardsApi(this._dioClient);

  /// Get authorization headers with current user's token
  Future<Map<String, String>> _getAuthHeaders() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw AppAuthException('Not authenticated');
    }
    return {
      'Authorization': 'Bearer ${session.accessToken}',
      'Content-Type': 'application/json',
    };
  }

  /// Get user's token balance
  Future<TokenBalanceModel> getBalance() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dioClient.get(
        '${AppConstants.apiBaseUrl}/api/rewards/balance',
        options: Options(headers: headers),
      );
      return TokenBalanceModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get reward history
  Future<List<TokenRewardModel>> getRewardHistory({int limit = 50}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dioClient.get(
        '${AppConstants.apiBaseUrl}/api/rewards/history',
        queryParameters: {'limit': limit},
        options: Options(headers: headers),
      );
      
      final rewards = response.data['rewards'] as List;
      return rewards.map((r) => TokenRewardModel.fromJson(r)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get reward configuration
  Future<RewardConfigModel> getConfig() async {
    try {
      final response = await _dioClient.get(
        '${AppConstants.apiBaseUrl}/api/rewards/config',
      );
      return RewardConfigModel.fromJson(response.data['config']);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Record earning a reward
  Future<EarnRewardResult> earnReward({
    required String reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dioClient.post(
        '${AppConstants.apiBaseUrl}/api/rewards/earn',
        data: {
          'reason': reason,
          'metadata': metadata ?? {},
        },
        options: Options(headers: headers),
      );
      
      return EarnRewardResult(
        success: response.data['success'] ?? false,
        amount: response.data['amount'] ?? 0,
        newBalance: response.data['newBalance'] ?? 0,
        rewardId: response.data['rewardId'],
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Update user's Solana wallet address
  Future<bool> updateWalletAddress(String walletAddress) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dioClient.post(
        '${AppConstants.apiBaseUrl}/api/rewards/wallet',
        data: {'walletAddress': walletAddress},
        options: Options(headers: headers),
      );
      return response.data['success'] ?? false;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Request withdrawal
  Future<WithdrawalResult> requestWithdrawal(int amount) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dioClient.post(
        '${AppConstants.apiBaseUrl}/api/rewards/withdraw',
        data: {'amount': amount},
        options: Options(headers: headers),
      );
      
      return WithdrawalResult(
        success: response.data['success'] ?? false,
        requestId: response.data['requestId'],
        amount: response.data['amount'] ?? 0,
        walletAddress: response.data['walletAddress'],
        status: response.data['status'],
        message: response.data['message'],
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get withdrawal history
  Future<List<WithdrawalRequestModel>> getWithdrawalHistory({int limit = 20}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _dioClient.get(
        '${AppConstants.apiBaseUrl}/api/rewards/withdrawals',
        queryParameters: {'limit': limit},
        options: Options(headers: headers),
      );
      
      final withdrawals = response.data['withdrawals'] as List;
      return withdrawals.map((w) => WithdrawalRequestModel.fromJson(w)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get system status (public endpoint)
  Future<RewardsSystemStatus> getSystemStatus() async {
    try {
      final response = await _dioClient.get(
        '${AppConstants.apiBaseUrl}/api/rewards/status',
      );
      
      return RewardsSystemStatus(
        withdrawalsEnabled: response.data['withdrawalsEnabled'] ?? false,
        hotWalletBalance: response.data['hotWalletBalance'],
        network: response.data['network'] ?? 'mainnet',
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic e) {
    if (e is DioException) {
      final message = e.response?.data?['error'] ?? e.message ?? 'Network error';
      if (e.response?.statusCode == 401) {
        return AppAuthException(message);
      }
      if (e.response?.statusCode == 429) {
        return RateLimitException(message);
      }
      return ServerException(message);
    }
    if (e is Exception) return e;
    return ServerException(e.toString());
  }
}

/// Result of earning a reward
class EarnRewardResult {
  final bool success;
  final int amount;
  final int newBalance;
  final String? rewardId;

  EarnRewardResult({
    required this.success,
    required this.amount,
    required this.newBalance,
    this.rewardId,
  });
}

/// Result of withdrawal request
class WithdrawalResult {
  final bool success;
  final String? requestId;
  final int amount;
  final String? walletAddress;
  final String? status;
  final String? message;

  WithdrawalResult({
    required this.success,
    this.requestId,
    required this.amount,
    this.walletAddress,
    this.status,
    this.message,
  });
}

/// System status for rewards
class RewardsSystemStatus {
  final bool withdrawalsEnabled;
  final int? hotWalletBalance;
  final String network;

  RewardsSystemStatus({
    required this.withdrawalsEnabled,
    this.hotWalletBalance,
    required this.network,
  });
}

/// Rate limit exception
class RateLimitException implements Exception {
  final String message;
  
  RateLimitException(this.message);
  
  @override
  String toString() => 'RateLimitException: $message';
}
