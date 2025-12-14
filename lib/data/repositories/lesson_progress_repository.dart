import '../data_sources/local/local_storage.dart';
import '../models/lesson_progress_model.dart';
import 'package:uuid/uuid.dart';

class LessonProgressRepository {
  final AppLocalStorage _localStorage;
  final _uuid = const Uuid();

  LessonProgressRepository(this._localStorage);

  /// Save or update lesson progress
  Future<LessonProgressModel> saveProgress(LessonProgressModel progress) async {
    final progressList = _localStorage.getLessonProgress();

    // Remove existing progress for this lesson if exists
    progressList.removeWhere((p) =>
        p['lessonId'] == progress.lessonId && p['userId'] == progress.userId);

    // Add new progress
    progressList.insert(0, progress.toJson());

    // Keep only last 100 items
    if (progressList.length > 100) {
      progressList.removeRange(100, progressList.length);
    }

    await _localStorage.saveLessonProgress(progressList);
    return progress;
  }

  /// Get progress for a specific lesson
  LessonProgressModel? getProgress(String userId, String lessonId) {
    final progressList = _localStorage.getLessonProgress();

    try {
      final progressJson = progressList.firstWhere(
        (p) => p['userId'] == userId && p['lessonId'] == lessonId,
        orElse: () => {},
      );

      if (progressJson.isEmpty) return null;

      return LessonProgressModel.fromJson(progressJson);
    } catch (e) {
      return null;
    }
  }

  /// Get all progress for a user
  List<LessonProgressModel> getUserProgress(String userId) {
    final progressList = _localStorage.getLessonProgress();

    return progressList
        .where((p) => p['userId'] == userId)
        .map((json) => LessonProgressModel.fromJson(json))
        .toList();
  }

  /// Get progress by lesson type
  List<LessonProgressModel> getProgressByType(
    String userId,
    LessonType lessonType,
  ) {
    return getUserProgress(userId)
        .where((p) => p.lessonType == lessonType)
        .toList();
  }

  /// Create new progress entry
  LessonProgressModel createProgress({
    required String userId,
    required String lessonId,
    required LessonType lessonType,
    Map<String, dynamic>? metadata,
  }) {
    return LessonProgressModel(
      id: _uuid.v4(),
      userId: userId,
      lessonId: lessonId,
      lessonType: lessonType,
      startedAt: DateTime.now(),
      metadata: metadata,
    );
  }
}
