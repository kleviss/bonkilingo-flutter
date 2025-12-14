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

class GrammarExerciseScreen extends ConsumerStatefulWidget {
  const GrammarExerciseScreen({super.key});

  @override
  ConsumerState<GrammarExerciseScreen> createState() =>
      _GrammarExerciseScreenState();
}

class _GrammarExerciseScreenState extends ConsumerState<GrammarExerciseScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _showResult = false;
  List<GrammarQuestion> _questions = [];
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

      // Generate questions from corrections
      if (chatHistory.isEmpty) {
        _questions = _generateSampleQuestions();
      } else {
        _questions = _generateQuestionsFromCorrections(chatHistory);
      }

      // Load progress
      final progressRepo = ref.read(lessonProgressRepositoryProvider);
      _progress = progressRepo.getProgress(userId, 'grammar_exercise');

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

  List<GrammarQuestion> _generateQuestionsFromCorrections(
      List<ChatSessionModel> sessions) {
    final questions = <GrammarQuestion>[];
    for (final session in sessions.take(10)) {
      // Create fill-in-the-blank questions from corrections
      final inputWords = session.inputText.split(' ');
      final correctedWords = session.correctedText.split(' ');

      if (inputWords.length == correctedWords.length && inputWords.length > 3) {
        // Find differences
        for (int i = 0;
            i < inputWords.length && i < correctedWords.length;
            i++) {
          if (inputWords[i].toLowerCase() != correctedWords[i].toLowerCase()) {
            final sentence = List<String>.from(correctedWords);
            sentence[i] = '_____';
            questions.add(GrammarQuestion(
              sentence: sentence.join(' '),
              correctAnswer: correctedWords[i],
              options: [
                correctedWords[i],
                inputWords[i],
                correctedWords[i == 0 ? 1 : i - 1],
                correctedWords[i == correctedWords.length - 1 ? i - 1 : i + 1],
              ]..shuffle(),
            ));
            if (questions.length >= 10) break;
          }
        }
      }
    }

    if (questions.isEmpty) {
      return _generateSampleQuestions();
    }

    return questions;
  }

  List<GrammarQuestion> _generateSampleQuestions() {
    return [
      GrammarQuestion(
        sentence: 'I _____ to the store yesterday.',
        correctAnswer: 'went',
        options: ['went', 'go', 'going', 'goes'],
      ),
      GrammarQuestion(
        sentence: 'She _____ a book right now.',
        correctAnswer: 'is reading',
        options: ['is reading', 'read', 'reads', 'reading'],
      ),
      GrammarQuestion(
        sentence: 'They _____ dinner when I arrived.',
        correctAnswer: 'were having',
        options: ['were having', 'have', 'had', 'having'],
      ),
      GrammarQuestion(
        sentence: 'He _____ speak three languages.',
        correctAnswer: 'can',
        options: ['can', 'could', 'will', 'would'],
      ),
      GrammarQuestion(
        sentence: 'We _____ finished the project yet.',
        correctAnswer: "haven't",
        options: ["haven't", "hasn't", "don't", "didn't"],
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

    // Show feedback
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(isCorrect ? 'Correct!' : 'Incorrect'),
        content: Text(
          isCorrect
              ? 'Great job! You got it right.'
              : 'The correct answer is: "${_questions[_currentQuestionIndex].correctAnswer}"',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _nextQuestion();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
      });
    } else {
      _completeExercise();
    }
  }

  Future<void> _completeExercise() async {
    final userId = ref.read(currentUserProvider).value?.id ?? '';
    final progressRepo = ref.read(lessonProgressRepositoryProvider);
    final rewardsNotifier = ref.read(rewardsStateProvider.notifier);

    final progress = _progress ??
        progressRepo.createProgress(
          userId: userId,
          lessonId: 'grammar_exercise',
          lessonType: LessonType.grammarExercise,
        );

    final completedProgress = progress.copyWith(
      score: _score,
      totalQuestions: _questions.length,
      correctAnswers: _score,
      completed: true,
      completedAt: DateTime.now(),
    );

    await progressRepo.saveProgress(completedProgress);
    await rewardsNotifier.earnLessonCompleteReward('grammar_exercise');

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
          middle: Text('Grammar Exercise'),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Grammar Exercise'),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_fix_high,
                    size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'No exercises available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete some text corrections to generate grammar exercises.',
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
        middle: Text('Grammar Exercise'),
      ),
      child: SafeArea(
        child:
            _showResult ? _buildResultView(theme) : _buildExerciseView(theme),
      ),
    );
  }

  Widget _buildExerciseView(ThemeHelper theme) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fill in the blank:',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  question.sentence,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
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
              'Exercise Complete!',
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

class GrammarQuestion {
  final String sentence;
  final String correctAnswer;
  final List<String> options;

  GrammarQuestion({
    required this.sentence,
    required this.correctAnswer,
    required this.options,
  });
}
