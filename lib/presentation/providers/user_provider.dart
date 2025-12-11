import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile_model.dart';
import 'providers.dart';
import 'auth_provider.dart';

// User profile provider
final userProfileProvider = FutureProvider<UserProfileModel?>((ref) async {
  final user = ref.watch(currentUserProvider).value;
  
  if (user == null) return null;
  
  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.getUserProfile(user.id);
});

// User profile state notifier
final userProfileStateProvider =
    StateNotifierProvider<UserProfileStateNotifier, UserProfileState>(
  (ref) {
    final userRepository = ref.watch(userRepositoryProvider);
    final user = ref.watch(currentUserProvider).value;
    return UserProfileStateNotifier(userRepository, user?.id);
  },
);

class UserProfileState {
  final UserProfileModel? profile;
  final bool isLoading;
  final String? error;

  UserProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  UserProfileState copyWith({
    UserProfileModel? profile,
    bool? isLoading,
    String? error,
  }) {
    return UserProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UserProfileStateNotifier extends StateNotifier<UserProfileState> {
  final _userRepository;
  final String? _userId;

  UserProfileStateNotifier(this._userRepository, this._userId)
      : super(UserProfileState()) {
    if (_userId != null) {
      loadProfile();
    }
  }

  Future<void> loadProfile() async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final profile = await _userRepository.getUserProfile(_userId);
      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateProfile(UserProfileModel profile) async {
    if (_userId == null) return;

    state = state.copyWith(isLoading: true);

    try {
      await _userRepository.updateUserProfile(_userId, profile);
      state = state.copyWith(
        profile: profile,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateFields(Map<String, dynamic> updates) async {
    if (_userId == null) return;

    try {
      await _userRepository.updateUserFields(_userId, updates);
      
      // Update local state
      if (state.profile != null) {
        final updatedProfile = UserProfileModel.fromJson({
          ...state.profile!.toJson(),
          ...updates,
        });
        state = state.copyWith(profile: updatedProfile);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void addBonkPoints(int points) {
    if (state.profile == null) return;

    final updatedProfile = state.profile!.copyWith(
      bonkPoints: state.profile!.bonkPoints + points,
    );

    state = state.copyWith(profile: updatedProfile);
    updateFields({'bonk_points': updatedProfile.bonkPoints});
  }

  void incrementCorrections() {
    if (state.profile == null) return;

    final updatedProfile = state.profile!.copyWith(
      totalCorrections: state.profile!.totalCorrections + 1,
    );

    state = state.copyWith(profile: updatedProfile);
    updateFields({'total_corrections': updatedProfile.totalCorrections});
  }

  void addLanguage(String language) {
    if (state.profile == null) return;

    if (!state.profile!.languagesLearned.contains(language)) {
      final updatedLanguages = [
        ...state.profile!.languagesLearned,
        language,
      ];

      final updatedProfile = state.profile!.copyWith(
        languagesLearned: updatedLanguages,
      );

      state = state.copyWith(profile: updatedProfile);
      updateFields({'languages_learned': updatedLanguages});
    }
  }
}

