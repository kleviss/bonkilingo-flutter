import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_helper.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../../data/models/lesson_progress_model.dart';
import '../../../data/models/chat_session_model.dart';
import '../../providers/providers.dart';

class VocabularyQuizScreen extends ConsumerStatefulWidget {
  const VocabularyQuizScreen({super.key});

  @override
  ConsumerState<VocabularyQuizScreen> createState() =>
      _VocabularyQuizScreenState();
}

class _VocabularyQuizScreenState extends ConsumerState<VocabularyQuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _showResult = false;
  List<VocabularyQuestion> _questions = [];
  bool _isLoading = true;
  LessonProgressModel? _progress;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserProvider).value?.id ?? '';
      final correctionRepo = ref.read(correctionRepositoryProvider);
      final chatHistory = await correctionRepo.getChatHistory(userId);

      // Extract words from corrections
      final words = _extractWordsFromCorrections(chatHistory);

      if (words.isEmpty) {
        // Generate sample questions if no corrections available
        _questions = _generateSampleQuestions();
      } else {
        _questions = _generateQuestionsFromWords(words);
      }

      // Load progress
      final progressRepo = ref.read(lessonProgressRepositoryProvider);
      _progress = progressRepo.getProgress(userId, 'vocabulary_quiz');

      if (_progress != null && _progress!.completed) {
        _currentQuestionIndex = _questions.length;
        _score = _progress!.score;
        _showResult = true;
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<String> _extractWordsFromCorrections(List<ChatSessionModel> sessions) {
    final words = <String>{};
    for (final session in sessions.take(20)) {
      final correctedWords = session.correctedText
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), ' ')
          .split(' ')
          .where((w) => w.length > 4)
          .take(5);
      words.addAll(correctedWords);
    }
    return words.toList();
  }

  List<VocabularyQuestion> _generateQuestionsFromWords(List<String> words) {
    final questions = <VocabularyQuestion>[];
    for (int i = 0; i < words.length && i < 10; i++) {
      final word = words[i];
      questions.add(VocabularyQuestion(
        word: word,
        correctAnswer: word,
        options: [
          word,
          words[(i + 1) % words.length],
          words[(i + 2) % words.length],
          words[(i + 3) % words.length],
        ]..shuffle(),
      ));
    }
    return questions;
  }

  List<VocabularyQuestion> _generateSampleQuestions() {
    return [
      VocabularyQuestion(
        word: 'hello',
        correctAnswer: 'hello',
        options: ['hello', 'goodbye', 'thanks', 'please'],
      ),
      VocabularyQuestion(
        word: 'thank you',
        correctAnswer: 'thank you',
        options: ['thank you', 'sorry', 'excuse me', 'welcome'],
      ),
      VocabularyQuestion(
        word: 'please',
        correctAnswer: 'please',
        options: ['please', 'yes', 'no', 'maybe'],
      ),
    ];
  }

  void _selectAnswer(String answer) {
    setState(() {
      _selectedAnswer = answer;
    });
  }

  Future<void> _submitAnswer() async {
    if (_selectedAnswer == null) return;

    final isCorrect =
        _questions[_currentQuestionIndex].correctAnswer == _selectedAnswer;

    if (isCorrect) {
      setState(() => _score++);
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
      });
    } else {
      await _completeQuiz();
    }
  }

  Future<void> _completeQuiz() async {
    final userId = ref.read(currentUserProvider).value?.id ?? '';
    final progressRepo = ref.read(lessonProgressRepositoryProvider);
    final rewardsNotifier = ref.read(rewardsStateProvider.notifier);

    final progress = _progress ??
        progressRepo.createProgress(
          userId: userId,
          lessonId: 'vocabulary_quiz',
          lessonType: LessonType.vocabularyQuiz,
        );

    final completedProgress = progress.copyWith(
      score: _score,
      totalQuestions: _questions.length,
      correctAnswers: _score,
      completed: true,
      completedAt: DateTime.now(),
    );

    await progressRepo.saveProgress(completedProgress);

    // Award reward
    await rewardsNotifier.earnLessonCompleteReward('vocabulary_quiz');

    setState(() {
      _showResult = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = ThemeHelper(themeMode);

    if (_isLoading) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Vocabulary Quiz'),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Vocabulary Quiz'),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.quiz,
                    size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'No vocabulary available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete some text corrections to generate vocabulary questions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Vocabulary Quiz'),
      ),
      child: SafeArea(
        child: _showResult ? _buildResultView(theme) : _buildQuizView(theme),
      ),
    );
  }

  Widget _buildQuizView(ThemeHelper theme) {
    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Progress indicator
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_currentQuestionIndex + 1}/${_questions.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Question
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              children: [
                Text(
                  'What does this word mean?',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  question.word,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Answer options
          ...question.options.map((option) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => _selectAnswer(option),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _selectedAnswer == option
                          ? theme.primary.withOpacity(0.1)
                          : theme.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedAnswer == option
                            ? theme.primary
                            : theme.border,
                        width: _selectedAnswer == option ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.textPrimary,
                            ),
                          ),
                        ),
                        if (_selectedAnswer == option)
                          Icon(
                            Icons.check_circle,
                            color: theme.primary,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 24),

          // Submit button
          CupertinoButton.filled(
            onPressed: _selectedAnswer == null ? null : _submitAnswer,
            child: const Text('Submit Answer'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultView(ThemeHelper theme) {
    final percentage = (_score / _questions.length * 100).round();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              percentage >= 70
                  ? Icons.check_circle
                  : Icons.sentiment_dissatisfied,
              size: 80,
              color: percentage >= 70
                  ? CupertinoColors.systemGreen
                  : theme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Quiz Complete!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Score: $_score/${_questions.length} ($percentage%)',
              style: TextStyle(
                fontSize: 20,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            CupertinoButton.filled(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class VocabularyQuestion {
  final String word;
  final String correctAnswer;
  final List<String> options;

  VocabularyQuestion({
    required this.word,
    required this.correctAnswer,
    required this.options,
  });
}
