import '../../core/constants/app_constants.dart';

class PointsService {
  /// Calculate points earned for text correction based on text length
  int calculateCorrectionPoints(String inputText) {
    final wordCount = inputText.trim().split(RegExp(r'\s+')).length;
    
    if (wordCount < AppConstants.smallTextWordCount) {
      return AppConstants.minCorrectionPoints;
    } else if (wordCount < AppConstants.mediumTextWordCount) {
      return AppConstants.mediumCorrectionPoints;
    } else {
      return AppConstants.largeCorrectionPoints;
    }
  }

  /// Calculate streak bonus points
  int calculateStreakBonus(int streakDays) {
    final weeks = (streakDays / 7).floor();
    return weeks * AppConstants.streakBonusPerWeek;
  }

  /// Get points for saving a lesson
  int getLessonSavePoints() {
    return AppConstants.lessonSavePoints;
  }

  /// Calculate level based on total corrections
  int calculateLevel(int totalCorrections) {
    // Simple leveling system: 1 level per 10 corrections
    return (totalCorrections / 10).floor() + 1;
  }

  /// Check if user can redeem a reward
  bool canRedeemReward(int currentPoints, int rewardCost) {
    return currentPoints >= rewardCost;
  }

  /// Calculate points needed for next level
  int pointsToNextLevel(int currentLevel) {
    return (currentLevel * 10) * 100; // Example: level 1 needs 1000 points
  }
}

