import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_session_model.freezed.dart';
part 'chat_session_model.g.dart';

@freezed
class ChatSessionModel with _$ChatSessionModel {
  const factory ChatSessionModel({
    required String id,
    required String userId,
    required String correctedText,
    required String inputText,
    required String language,
    required String model,
    DateTime? createdAt,
  }) = _ChatSessionModel;

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionModelFromJson(json);
}

