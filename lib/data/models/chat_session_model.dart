import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_session_model.freezed.dart';
part 'chat_session_model.g.dart';

@freezed
class ChatSessionModel with _$ChatSessionModel {
  const ChatSessionModel._();

  const factory ChatSessionModel({
    required String id,
    required String userId,
    required String correctedText,
    required String inputText,
    required String language,
    required String model,
    DateTime? createdAt,
    /// Where the correction was made: [sourceApp] or [sourceKeyboard].
    @Default(ChatSessionModel.sourceApp) String source,
  }) = _ChatSessionModel;

  static const sourceApp = 'app';
  static const sourceKeyboard = 'keyboard';

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionModelFromJson(json);
}

