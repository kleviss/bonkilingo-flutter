import 'package:freezed_annotation/freezed_annotation.dart';

part 'lesson_request.freezed.dart';
part 'lesson_request.g.dart';

@freezed
class LessonRequest with _$LessonRequest {
  const factory LessonRequest({
    required String situation,
    required String language,
    @Default('gpt-3.5-turbo') String model,
  }) = _LessonRequest;

  factory LessonRequest.fromJson(Map<String, dynamic> json) =>
      _$LessonRequestFromJson(json);
}

@freezed
class LessonResponse with _$LessonResponse {
  const factory LessonResponse({
    required String reply,
  }) = _LessonResponse;

  factory LessonResponse.fromJson(Map<String, dynamic> json) =>
      _$LessonResponseFromJson(json);
}

