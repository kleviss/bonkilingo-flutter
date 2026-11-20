import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons, ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/brand_colors.dart';
import '../../widgets/brand/brand_page.dart';
import '../../widgets/brand/pill_button.dart';
import '../../widgets/brand/quiz_widgets.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/rewards_provider.dart';
import '../../../data/models/lesson_progress_model.dart';
import '../../../data/models/chat_session_model.dart';
import '../../providers/providers.dart';

const _blue = Color(0xFF4F8EF7);

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

  /// Whether the questions came from the user's corrections, not samples.
  bool _fromCorrections = false;

  /// Set once the last answer is in, so the final tap can't run twice.
  bool _completing = false;

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
        _fromCorrections = true;
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
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final p = BrandPalette(isDark);

    final Widget body;
    if (_isLoading) {
      body = const Center(child: CupertinoActivityIndicator());
    } else if (_questions.isEmpty) {
      body = QuizEmptyState(
        palette: p,
        icon: Icons.quiz_outlined,
        color: _blue,
        title: 'No vocabulary yet',
        message:
            'Complete some text corrections to generate vocabulary questions.',
      );
    } else {
      body = _showResult ? _buildResultView(p) : _buildQuizView(p);
    }

    return BrandPage(isDark: isDark, title: 'Vocabulary quiz', child: body);
  }

  Widget _buildQuizView(BrandPalette p) {
    final question = _questions[_currentQuestionIndex];
    final isLast = _currentQuestionIndex == _questions.length - 1;

    return QuizLayout(
      action: PillButton(
        label: isLast ? 'Finish' : 'Next',
        loading: _completing,
        onPressed: _selectedAnswer == null
            ? null
            : () {
                if (isLast) setState(() => _completing = true);
                _submitAnswer();
              },
      ),
      children: [
        QuizProgressBar(
          palette: p,
          current: _currentQuestionIndex + 1,
          total: _questions.length,
        ),
        const SizedBox(height: 20),
        QuizQuestionCard(
          palette: p,
          fromCorrections: _fromCorrections,
          prompt: 'What does this word mean?',
          child: QuizSunkenBox(
            palette: p,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 22),
            child: Text(
              question.word,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: p.text,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnswerGrid(
          tiles: [
            for (final option in question.options)
              AnswerTile(
                palette: p,
                label: option,
                state: _selectedAnswer == option
                    ? AnswerTileState.selected
                    : AnswerTileState.idle,
                onTap: () => _selectAnswer(option),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultView(BrandPalette p) {
    return QuizLayout(
      action: PillButton(
        label: 'Done',
        onPressed: () => Navigator.of(context).pop(),
      ),
      children: [
        QuizResultCard(
          title: 'Quiz complete',
          score: _score,
          total: _questions.length,
        ),
      ],
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
