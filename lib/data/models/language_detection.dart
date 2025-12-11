import 'package:freezed_annotation/freezed_annotation.dart';

part 'language_detection.freezed.dart';
part 'language_detection.g.dart';

@freezed
class LanguageDetectionRequest with _$LanguageDetectionRequest {
  const factory LanguageDetectionRequest({
    required String text,
  }) = _LanguageDetectionRequest;

  factory LanguageDetectionRequest.fromJson(Map<String, dynamic> json) =>
      _$LanguageDetectionRequestFromJson(json);
}

@freezed
class LanguageDetectionResponse with _$LanguageDetectionResponse {
  const factory LanguageDetectionResponse({
    required String language,
  }) = _LanguageDetectionResponse;

  factory LanguageDetectionResponse.fromJson(Map<String, dynamic> json) =>
      _$LanguageDetectionResponseFromJson(json);
}

