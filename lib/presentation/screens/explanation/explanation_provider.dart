import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';

final explanationStateProvider =
    StateNotifierProvider<ExplanationStateNotifier, ExplanationState>(
  (ref) {
    final lessonRepository = ref.watch(lessonRepositoryProvider);
    final userProfileState = ref.watch(userProfileStateProvider.notifier);
    final currentUser = ref.watch(currentUserProvider).value;

    return ExplanationStateNotifier(
      lessonRepository,
      userProfileState,
      currentUser?.id,
    );
  },
);

class Message {
  final String sender; // 'user' or 'gpt'
  final String text;

  Message({required this.sender, required this.text});
}

class ExplanationState {
  final List<Message> messages;
  final bool isLoading;
  final bool isCreatingLesson;
  final bool lessonCreated;
  final String? createdLessonId;
  final String? error;

  ExplanationState({
    this.messages = const [],
    this.isLoading = false,
    this.isCreatingLesson = false,
    this.lessonCreated = false,
    this.createdLessonId,
    this.error,
  });

  ExplanationState copyWith({
    List<Message>? messages,
    bool? isLoading,
    bool? isCreatingLesson,
    bool? lessonCreated,
    String? createdLessonId,
    String? error,
    bool clearError = false,
  }) {
    return ExplanationState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isCreatingLesson: isCreatingLesson ?? this.isCreatingLesson,
      lessonCreated: lessonCreated ?? this.lessonCreated,
      createdLessonId: createdLessonId ?? this.createdLessonId,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ExplanationStateNotifier extends StateNotifier<ExplanationState> {
  final _lessonRepository;
  final _userProfileState;
  final String? _userId;

  ExplanationStateNotifier(
    this._lessonRepository,
    this._userProfileState,
    this._userId,
  ) : super(ExplanationState());

  Future<void> initialize(String correctedText, String inputText) async {
    state = state.copyWith(isLoading: true);

    try {
      // Request initial explanation from backend
      // This will use the chat endpoint
      final explanation = await _getInitialExplanation(correctedText, inputText);

      state = state.copyWith(
        messages: [
          Message(sender: 'gpt', text: explanation),
        ],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        messages: [
          Message(
            sender: 'gpt',
            text: 'Sorry, I couldn\'t fetch the explanation.',
          ),
        ],
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<String> _getInitialExplanation(
    String correctedText,
    String inputText,
  ) async {
    // Use the lesson repository's chat functionality
    // We need to add a chat method or use existing generateLesson
    // For now, return a placeholder
    return 'Here are the main corrections I made:\n\n• Grammar improvements\n• Spelling corrections\n• Punctuation fixes\n\nFeel free to ask me any questions about the corrections!';
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    final userMessage = Message(sender: 'user', text: text);
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
    );

    try {
      // Here you would call the backend chat endpoint
      // For now, using a placeholder response
      await Future.delayed(const Duration(seconds: 1));

      final gptMessage = Message(
        sender: 'gpt',
        text: 'I understand your question. Let me help you with that...',
      );

      state = state.copyWith(
        messages: [...state.messages, gptMessage],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> createTinyLesson() async {
    if (state.messages.isEmpty) return;

    state = state.copyWith(isCreatingLesson: true, clearError: true);

    try {
      // Convert messages to API format
      final apiMessages = state.messages.map((m) => {
        'role': m.sender == 'user' ? 'user' : 'assistant',
        'content': m.text,
      }).toList();

      // Generate lesson summary from conversation
      final lessonContent = await _lessonRepository.generateLessonFromConversation(
        messages: apiMessages,
      );

      // Create lesson title from conversation
      final firstUserMessage = state.messages
          .firstWhere((m) => m.sender == 'user', orElse: () => state.messages.first);
      final title = firstUserMessage.text.length > 30
          ? '${firstUserMessage.text.substring(0, 30)}...'
          : firstUserMessage.text;
      final lessonTitle = 'Lesson from chat: $title';

      // Save the lesson
      final savedLesson = await _lessonRepository.saveLesson(
        userId: _userId ?? '',
        title: lessonTitle,
        content: lessonContent,
      );

      // Award points for creating lesson
      _userProfileState.addBonkPoints(15);

      state = state.copyWith(
        isCreatingLesson: false,
        lessonCreated: true,
        createdLessonId: savedLesson.id,
      );
    } catch (e) {
      state = state.copyWith(
        isCreatingLesson: false,
        error: e.toString(),
      );
    }
  }

  void resetLessonCreated() {
    state = state.copyWith(lessonCreated: false, createdLessonId: null);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

