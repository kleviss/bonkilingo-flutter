import 'package:freezed_annotation/freezed_annotation.dart';

part 'lesson_progress_model.freezed.dart';
part 'lesson_progress_model.g.dart';

enum LessonType {
  vocabularyQuiz,
  sentenceConstruction,
  grammarExercise,
  structuredLesson,
}

@freezed
class LessonProgressModel with _$LessonProgressModel {
  const factory LessonProgressModel({
    required String id,
    required String userId,
    required String lessonId,
    required LessonType lessonType,
    @Default(0) int score,
    @Default(0) int totalQuestions,
    @Default(0) int correctAnswers,
    @Default(false) bool completed,
    DateTime? startedAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) = _LessonProgressModel;

  factory LessonProgressModel.fromJson(Map<String, dynamic> json) =>
      _$LessonProgressModelFromJson(json);
}

