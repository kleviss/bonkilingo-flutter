import 'package:freezed_annotation/freezed_annotation.dart';

part 'correction_request.freezed.dart';
part 'correction_request.g.dart';

@freezed
class CorrectionRequest with _$CorrectionRequest {
  const factory CorrectionRequest({
    required String text,
    required String language,
    @Default('gpt-3.5-turbo') String model,
  }) = _CorrectionRequest;

  factory CorrectionRequest.fromJson(Map<String, dynamic> json) =>
      _$CorrectionRequestFromJson(json);
}

@freezed
class CorrectionResponse with _$CorrectionResponse {
  const factory CorrectionResponse({
    required String corrected,
  }) = _CorrectionResponse;

  factory CorrectionResponse.fromJson(Map<String, dynamic> json) =>
      _$CorrectionResponseFromJson(json);
}

