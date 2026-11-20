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

  /// Whether the questions came from the user's corrections, not samples.
  bool _fromCorrections = false;

  /// Set once the last answer is in, so the final tap can't run twice.
  bool _completing = false;

  /// Whether the current answer was checked and its feedback is showing.
  bool _answered = false;

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

    _fromCorrections = true;
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

    // Show feedback inline; Continue moves on via _nextQuestion.
    setState(() => _answered = true);
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
        _answered = false;
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
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final p = BrandPalette(isDark);

    final Widget body;
    if (_isLoading) {
      body = const Center(child: CupertinoActivityIndicator());
    } else if (_questions.isEmpty) {
      body = QuizEmptyState(
        palette: p,
        icon: Icons.spellcheck,
        color: BrandColors.leaf,
        title: 'No exercises yet',
        message:
            'Complete some text corrections to generate grammar exercises.',
      );
    } else {
      body = _showResult ? _buildResultView(p) : _buildExerciseView(p);
    }

    return BrandPage(isDark: isDark, title: 'Grammar exercises', child: body);
  }

  AnswerTileState _tileState(String option, GrammarQuestion question) {
    if (_answered) {
      if (option == question.correctAnswer) return AnswerTileState.correct;
      if (option == _selectedAnswer) return AnswerTileState.wrong;
      return AnswerTileState.idle;
    }
    return option == _selectedAnswer
        ? AnswerTileState.selected
        : AnswerTileState.idle;
  }

  /// The sentence with its gap filled: muted blank, the picked word in
  /// tangerine, or the right answer in green once checked.
  Widget _buildSentence(BrandPalette p, GrammarQuestion question) {
    const gap = '_____';
    final base = TextStyle(fontSize: 18, height: 1.45, color: p.text);
    final index = question.sentence.indexOf(gap);
    if (index < 0) return Text(question.sentence, style: base);

    final String gapText;
    final TextStyle gapStyle;
    if (_answered) {
      gapText = ' ${question.correctAnswer} ';
      gapStyle = TextStyle(
        color: BrandPalette.green,
        fontWeight: FontWeight.w700,
        backgroundColor: p.greenBg,
      );
    } else if (_selectedAnswer != null) {
      gapText = ' $_selectedAnswer ';
      gapStyle = const TextStyle(
        color: BrandColors.tangerine,
        fontWeight: FontWeight.w700,
      );
    } else {
      gapText = gap;
      gapStyle = TextStyle(color: p.muted, fontWeight: FontWeight.w700);
    }

    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: question.sentence.substring(0, index)),
          TextSpan(text: gapText, style: gapStyle),
          TextSpan(text: question.sentence.substring(index + gap.length)),
        ],
      ),
    );
  }

  Widget _buildExerciseView(BrandPalette p) {
    final question = _questions[_currentQuestionIndex];
    final isLast = _currentQuestionIndex == _questions.length - 1;
    final isCorrect = _selectedAnswer == question.correctAnswer;

    return QuizLayout(
      feedback: _answered
          ? QuizFeedbackCard(
              palette: p,
              correct: isCorrect,
              message: isCorrect
                  ? 'Great job! You got it right.'
                  : 'The correct answer is "${question.correctAnswer}".',
            )
          : null,
      action: _answered
          ? PillButton(
              label: isLast ? 'Finish' : 'Continue',
              loading: _completing,
              onPressed: () {
                if (isLast) setState(() => _completing = true);
                _nextQuestion();
              },
            )
          : PillButton(
              label: 'Check',
              onPressed: _selectedAnswer == null ? null : _submitAnswer,
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
          prompt: 'Fill the gap',
          child: QuizSunkenBox(
            palette: p,
            child: _buildSentence(p, question),
          ),
        ),
        const SizedBox(height: 16),
        AnswerGrid(
          tiles: [
            for (final option in question.options)
              AnswerTile(
                palette: p,
                label: option,
                state: _tileState(option, question),
                onTap: _answered ? null : () => _selectAnswer(option),
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
          title: 'Exercise complete',
          score: _score,
          total: _questions.length,
        ),
      ],
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
