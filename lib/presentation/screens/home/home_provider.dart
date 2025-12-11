import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/language_constants.dart';
import '../../../data/models/correction_request.dart';
import '../../providers/providers.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

final homeStateProvider = StateNotifierProvider<HomeStateNotifier, HomeState>(
  (ref) {
    final correctionRepository = ref.watch(correctionRepositoryProvider);
    final languageRepository = ref.watch(languageRepositoryProvider);
    final userProfileState = ref.watch(userProfileStateProvider.notifier);
    final pointsService = ref.watch(pointsServiceProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return HomeStateNotifier(
      correctionRepository,
      languageRepository,
      userProfileState,
      pointsService,
      currentUser?.id,
    );
  },
);

class HomeState {
  final String selectedLanguage;
  final String? detectedLanguage;
  final bool autoDetect;
  final bool isDetecting;
  final bool isLoading;
  final String? correctedText;
  final String? error;

  HomeState({
    this.selectedLanguage = LanguageConstants.defaultLanguage,
    this.detectedLanguage,
    this.autoDetect = true,
    this.isDetecting = false,
    this.isLoading = false,
    this.correctedText,
    this.error,
  });

  HomeState copyWith({
    String? selectedLanguage,
    String? detectedLanguage,
    bool? autoDetect,
    bool? isDetecting,
    bool? isLoading,
    String? correctedText,
    String? error,
  }) {
    return HomeState(
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      detectedLanguage: detectedLanguage,
      autoDetect: autoDetect ?? this.autoDetect,
      isDetecting: isDetecting ?? this.isDetecting,
      isLoading: isLoading ?? this.isLoading,
      correctedText: correctedText,
      error: error,
    );
  }
}

class HomeStateNotifier extends StateNotifier<HomeState> {
  final _correctionRepository;
  final _languageRepository;
  final _userProfileState;
  final _pointsService;
  final String? _userId;

  Timer? _debounceTimer;

  HomeStateNotifier(
    this._correctionRepository,
    this._languageRepository,
    this._userProfileState,
    this._pointsService,
    this._userId,
  ) : super(HomeState());

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void selectLanguage(String language) {
    state = state.copyWith(
      selectedLanguage: language,
      autoDetect: false,
      detectedLanguage: null,
    );
  }

  void toggleAutoDetect() {
    state = state.copyWith(
      autoDetect: !state.autoDetect,
      detectedLanguage: null,
    );
  }

  void onTextChanged(String text) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    if (!state.autoDetect) return;

    final trimmedText = text.trim();
    if (trimmedText.length < AppConstants.minLanguageDetectionLength ||
        trimmedText.split(RegExp(r'\s+')).length <
            AppConstants.minLanguageDetectionWords) {
      state = state.copyWith(isDetecting: false, detectedLanguage: null);
      return;
    }

    state = state.copyWith(isDetecting: true);

    // Debounce language detection
    _debounceTimer = Timer(AppConstants.debounceDelay, () {
      _detectLanguage(trimmedText);
    });
  }

  Future<void> _detectLanguage(String text) async {
    try {
      final language = await _languageRepository.detectLanguage(text);
      
      if (mounted) {
        state = state.copyWith(
          detectedLanguage: language,
          isDetecting: false,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isDetecting: false,
          detectedLanguage: null,
        );
      }
    }
  }

  Future<void> correctText(String inputText) async {
    if (inputText.trim().isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final language = state.detectedLanguage ?? state.selectedLanguage;
      
      final request = CorrectionRequest(
        text: inputText,
        language: language,
        model: LanguageConstants.defaultModel,
      );

      final corrected = await _correctionRepository.correctText(request);

      // Calculate and award points
      final points = _pointsService.calculateCorrectionPoints(inputText);
      _userProfileState.addBonkPoints(points);
      _userProfileState.incrementCorrections();
      _userProfileState.addLanguage(language);

      // Save chat session
      await _correctionRepository.saveChatSession(
        userId: _userId ?? '',
        correctedText: corrected,
        inputText: inputText,
        language: language,
        model: LanguageConstants.defaultModel,
      );

      state = state.copyWith(
        correctedText: corrected,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

