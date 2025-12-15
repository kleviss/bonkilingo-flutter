/// Token reward model for tracking BONK token earnings
class TokenRewardModel {
  final String id;
  final String usedId;
  final int amount;
  final String tokenType;
  final String reason;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  TokenRewardModel({
    required this.id,
    required this.usedId,
    required this.amount,
    required this.tokenType,
    required this.reason,
    required this.metadata,
    required this.createdAt,
  });

  factory TokenRewardModel.fromJson(Map<String, dynamic> json) {
    return TokenRewardModel(
      id: json['id'] as String,
      usedId: json['user_id'] as String,
      amount: json['amount'] as int,
      tokenType: json['token_type'] as String? ?? 'BONK',
      reason: json['reason'] as String,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': usedId,
      'amount': amount,
      'token_type': tokenType,
      'reason': reason,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Get a human-readable reason
  String get readableReason {
    switch (reason) {
      case 'correction':
        return 'Text Correction';
      case 'lesson_complete':
        return 'Lesson Completed';
      case 'lesson_save':
        return 'Lesson Saved';
      case 'daily_streak':
        return 'Daily Streak Bonus';
      case 'weekly_streak':
        return 'Weekly Streak Bonus';
      case 'referral':
        return 'Referral Bonus';
      default:
        return reason;
    }
  }
}

/// Withdrawal request model
class WithdrawalRequestModel {
  final String id;
  final String userId;
  final String walletAddress;
  final int amount;
  final String tokenType;
  final String status;
  final String? txSignature;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? processedAt;

  WithdrawalRequestModel({
    required this.id,
    required this.userId,
    required this.walletAddress,
    required this.amount,
    required this.tokenType,
    required this.status,
    this.txSignature,
    this.errorMessage,
    required this.createdAt,
    this.processedAt,
  });

  factory WithdrawalRequestModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalRequestModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      walletAddress: json['wallet_address'] as String,
      amount: json['amount'] as int,
      tokenType: json['token_type'] as String? ?? 'BONK',
      status: json['status'] as String,
      txSignature: json['tx_signature'] as String?,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      processedAt: json['processed_at'] != null 
          ? DateTime.parse(json['processed_at'] as String) 
          : null,
    );
  }

  /// Check if withdrawal is pending
  bool get isPending => status == 'pending' || status == 'processing';

  /// Check if withdrawal completed successfully
  bool get isCompleted => status == 'completed';

  /// Check if withdrawal failed
  bool get isFailed => status == 'failed';

  /// Get Solana explorer URL for transaction
  String? get explorerUrl {
    if (txSignature == null) return null;
    return 'https://solscan.io/tx/$txSignature';
  }
}

/// User's token balance summary
class TokenBalanceModel {
  final int pendingBalance;
  final int totalEarned;
  final int totalWithdrawn;
  final String? walletAddress;
  final bool withdrawalsEnabled;
  final int minWithdrawal;

  TokenBalanceModel({
    required this.pendingBalance,
    required this.totalEarned,
    required this.totalWithdrawn,
    this.walletAddress,
    required this.withdrawalsEnabled,
    required this.minWithdrawal,
  });

  factory TokenBalanceModel.fromJson(Map<String, dynamic> json) {
    return TokenBalanceModel(
      pendingBalance: json['pendingBalance'] as int? ?? 0,
      totalEarned: json['totalEarned'] as int? ?? 0,
      totalWithdrawn: json['totalWithdrawn'] as int? ?? 0,
      walletAddress: json['walletAddress'] as String?,
      withdrawalsEnabled: json['withdrawalsEnabled'] as bool? ?? false,
      minWithdrawal: json['minWithdrawal'] as int? ?? 10000,
    );
  }

  /// Check if user can withdraw
  bool get canWithdraw => 
      withdrawalsEnabled && 
      walletAddress != null && 
      pendingBalance >= minWithdrawal;

  /// Amount available for withdrawal
  int get availableForWithdrawal => 
      pendingBalance >= minWithdrawal ? pendingBalance : 0;
}

/// Reward configuration from server
class RewardConfigModel {
  final int correctionSmall;
  final int correctionMedium;
  final int correctionLarge;
  final int lessonComplete;
  final int lessonSave;
  final int dailyStreakBonus;
  final int weeklyStreakBonus;
  final int referralBonus;
  final int minWithdrawal;

  RewardConfigModel({
    required this.correctionSmall,
    required this.correctionMedium,
    required this.correctionLarge,
    required this.lessonComplete,
    required this.lessonSave,
    required this.dailyStreakBonus,
    required this.weeklyStreakBonus,
    required this.referralBonus,
    required this.minWithdrawal,
  });

  factory RewardConfigModel.fromJson(Map<String, dynamic> json) {
    return RewardConfigModel(
      correctionSmall: json['correction_small'] as int? ?? 100,
      correctionMedium: json['correction_medium'] as int? ?? 250,
      correctionLarge: json['correction_large'] as int? ?? 500,
      lessonComplete: json['lesson_complete'] as int? ?? 200,
      lessonSave: json['lesson_save'] as int? ?? 100,
      dailyStreakBonus: json['daily_streak_bonus'] as int? ?? 150,
      weeklyStreakBonus: json['weekly_streak_bonus'] as int? ?? 1000,
      referralBonus: json['referral_bonus'] as int? ?? 5000,
      minWithdrawal: json['min_withdrawal'] as int? ?? 10000,
    );
  }

  /// Get reward amount for correction based on word count
  int getRewardForCorrection(int wordCount) {
    if (wordCount < 10) return correctionSmall;
    if (wordCount < 50) return correctionMedium;
    return correctionLarge;
  }
}


