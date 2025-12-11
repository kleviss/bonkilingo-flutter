import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/lesson_request.dart';
import '../../../data/models/lesson_model.dart';
import '../../providers/providers.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

enum LearnTool { tinyLesson, flashcards }

final learnStateProvider = StateNotifierProvider<LearnStateNotifier, LearnState>(
  (ref) {
    final lessonRepository = ref.watch(lessonRepositoryProvider);
    final userProfileState = ref.watch(userProfileStateProvider.notifier);
    final pointsService = ref.watch(pointsServiceProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return LearnStateNotifier(
      lessonRepository,
      userProfileState,
      pointsService,
      currentUser?.id,
    );
  },
);

class LearnState {
  final LearnTool? activeTool;
  final String situationInput;
  final String selectedLanguage;
  final bool isLoading;
  final String? generatedLesson;
  final List<LessonModel> savedLessons;
  final String? error;

  LearnState({
    this.activeTool,
    this.situationInput = '',
    this.selectedLanguage = 'english',
    this.isLoading = false,
    this.generatedLesson,
    this.savedLessons = const [],
    this.error,
  });

  LearnState copyWith({
    LearnTool? activeTool,
    String? situationInput,
    String? selectedLanguage,
    bool? isLoading,
    String? generatedLesson,
    List<LessonModel>? savedLessons,
    String? error,
  }) {
    return LearnState(
      activeTool: activeTool,
      situationInput: situationInput ?? this.situationInput,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      isLoading: isLoading ?? this.isLoading,
      generatedLesson: generatedLesson,
      savedLessons: savedLessons ?? this.savedLessons,
      error: error,
    );
  }
}

class LearnStateNotifier extends StateNotifier<LearnState> {
  final _lessonRepository;
  final _userProfileState;
  final _pointsService;
  final String? _userId;

  LearnStateNotifier(
    this._lessonRepository,
    this._userProfileState,
    this._pointsService,
    this._userId,
  ) : super(LearnState()) {
    _loadSavedLessons();
  }

  void setActiveTool(LearnTool tool) {
    state = state.copyWith(activeTool: tool);
    if (tool == LearnTool.flashcards) {
      _loadSavedLessons();
    }
  }

  void clearActiveTool() {
    state = state.copyWith(
      activeTool: null,
      generatedLesson: null,
      situationInput: '',
    );
  }

  void updateSituationInput(String input) {
    state = state.copyWith(situationInput: input);
  }

  void updateLanguage(String language) {
    state = state.copyWith(selectedLanguage: language);
  }

  Future<void> generateLesson() async {
    if (state.situationInput.trim().isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final request = LessonRequest(
        situation: state.situationInput,
        language: state.selectedLanguage,
      );

      final lesson = await _lessonRepository.generateLesson(request);

      // Award points for generating a lesson
      _userProfileState.addBonkPoints(10);

      state = state.copyWith(
        generatedLesson: lesson,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> saveLesson() async {
    if (state.generatedLesson == null || state.situationInput.isEmpty) return;

    try {
      final title = state.situationInput.length > 30
          ? '${state.situationInput.substring(0, 30)}...'
          : state.situationInput;

      final lesson = await _lessonRepository.saveLesson(
        userId: _userId ?? '',
        title: title,
        content: state.generatedLesson!,
      );

      // Award points for saving
      final points = _pointsService.getLessonSavePoints();
      _userProfileState.addBonkPoints(points);

      // Update saved lessons list
      state = state.copyWith(
        savedLessons: [lesson, ...state.savedLessons],
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> _loadSavedLessons() async {
    try {
      final lessons = await _lessonRepository.getSavedLessons(_userId);
      state = state.copyWith(savedLessons: lessons);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteLesson(String lessonId) async {
    try {
      await _lessonRepository.deleteLesson(lessonId, _userId);
      
      final updatedLessons = state.savedLessons
          .where((lesson) => lesson.id != lessonId)
          .toList();
      
      state = state.copyWith(savedLessons: updatedLessons);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

