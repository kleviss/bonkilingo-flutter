import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile_model.freezed.dart';
part 'user_profile_model.g.dart';

@freezed
class UserProfileModel with _$UserProfileModel {
  const factory UserProfileModel({
    required String id,
    required String email,
    @Default(0) int bonkPoints,
    @Default(0) int totalCorrections,
    @Default([]) List<String> languagesLearned,
    @Default(0) int streakDays,
    @Default(1) int level,
    @Default(false) bool dailyChallenge,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserProfileModel;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      _$UserProfileModelFromJson(json);
}

