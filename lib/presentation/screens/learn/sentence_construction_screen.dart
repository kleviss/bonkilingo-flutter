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

const _purple = Color(0xFFB07CF5);

class SentenceConstructionScreen extends ConsumerStatefulWidget {
  const SentenceConstructionScreen({super.key});

  @override
  ConsumerState<SentenceConstructionScreen> createState() =>
      _SentenceConstructionScreenState();
}

class _SentenceConstructionScreenState
    extends ConsumerState<SentenceConstructionScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  List<String> _selectedWords = [];
  List<String> _availableWords = [];
  bool _showResult = false;
  List<SentenceQuestion> _questions = [];
  bool _isLoading = true;
  LessonProgressModel? _progress;

  /// Whether the questions came from the user's corrections, not samples.
  bool _fromCorrections = false;

  /// Whether the current answer was checked and its feedback is showing.
  bool _answered = false;
  bool _lastAnswerCorrect = false;

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
        _questions = _generateSampleQuestions();
      } else {
        _questions = _generateQuestionsFromWords(words);
        _fromCorrections = true;
      }

      // Load progress
      final progressRepo = ref.read(lessonProgressRepositoryProvider);
      _progress = progressRepo.getProgress(userId, 'sentence_construction');

      if (_progress != null && _progress!.completed) {
        _currentQuestionIndex = _questions.length;
        _score = _progress!.score;
        _showResult = true;
      } else {
        _loadQuestion();
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadQuestion() {
    if (_currentQuestionIndex < _questions.length) {
      final question = _questions[_currentQuestionIndex];
      _availableWords = List.from(question.words)..shuffle();
      _selectedWords = [];
    }
  }

  List<String> _extractWordsFromCorrections(List<ChatSessionModel> sessions) {
    final words = <String>{};
    for (final session in sessions.take(20)) {
      final correctedWords = session.correctedText
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), ' ')
          .split(' ')
          .where((w) => w.length > 3)
          .take(10);
      words.addAll(correctedWords);
    }
    return words.toList();
  }

  List<SentenceQuestion> _generateQuestionsFromWords(List<String> words) {
    final questions = <SentenceQuestion>[];
    for (int i = 0; i < words.length && i < 8; i += 4) {
      final sentenceWords = words.skip(i).take(4).toList();
      if (sentenceWords.length >= 3) {
        questions.add(SentenceQuestion(
          targetSentence: sentenceWords.join(' '),
          words: sentenceWords,
        ));
      }
    }
    return questions;
  }

  List<SentenceQuestion> _generateSampleQuestions() {
    return [
      SentenceQuestion(
        targetSentence: 'hello how are you',
        words: ['hello', 'how', 'are', 'you', 'good', 'fine'],
      ),
      SentenceQuestion(
        targetSentence: 'thank you very much',
        words: ['thank', 'you', 'very', 'much', 'please', 'welcome'],
      ),
      SentenceQuestion(
        targetSentence: 'where is the bathroom',
        words: ['where', 'is', 'the', 'bathroom', 'here', 'there'],
      ),
    ];
  }

  void _selectWord(String word) {
    setState(() {
      _selectedWords.add(word);
      _availableWords.remove(word);
    });
  }

  void _removeWord(String word) {
    setState(() {
      _selectedWords.remove(word);
      _availableWords.add(word);
      _availableWords.shuffle();
    });
  }

  Future<void> _checkAnswer() async {
    final question = _questions[_currentQuestionIndex];
    final userSentence = _selectedWords.join(' ').toLowerCase().trim();
    final targetSentence = question.targetSentence.toLowerCase().trim();

    final isCorrect = userSentence == targetSentence;

    if (isCorrect) {
      setState(() => _score++);
    }

    // Show feedback inline; Continue moves on via _nextQuestion.
    setState(() {
      _answered = true;
      _lastAnswerCorrect = isCorrect;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _answered = false;
        _loadQuestion();
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
          lessonId: 'sentence_construction',
          lessonType: LessonType.sentenceConstruction,
        );

    final completedProgress = progress.copyWith(
      score: _score,
      totalQuestions: _questions.length,
      correctAnswers: _score,
      completed: true,
      completedAt: DateTime.now(),
    );

    await progressRepo.saveProgress(completedProgress);
    await rewardsNotifier.earnLessonCompleteReward('sentence_construction');

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
        icon: Icons.view_agenda_outlined,
        color: _purple,
        title: 'No words yet',
        message:
            'Complete some text corrections to generate sentence building exercises.',
      );
    } else {
      body = _showResult ? _buildResultView(p) : _buildExerciseView(p);
    }

    return BrandPage(isDark: isDark, title: 'Sentence building', child: body);
  }

  Widget _buildExerciseView(BrandPalette p) {
    final question = _questions[_currentQuestionIndex];
    final isLast = _currentQuestionIndex == _questions.length - 1;
    final isCorrect = _answered && _lastAnswerCorrect;

    return QuizLayout(
      feedback: _answered
          ? QuizFeedbackCard(
              palette: p,
              correct: isCorrect,
              message: isCorrect
                  ? 'Great job! You built the sentence correctly.'
                  : 'The correct sentence is "${question.targetSentence}".',
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
              onPressed: _selectedWords.isEmpty ? null : _checkAnswer,
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
          prompt: 'Construct a sentence using these words',
          child: QuizSunkenBox(
            palette: p,
            borderColor: _answered
                ? (isCorrect ? BrandPalette.green : BrandPalette.red)
                : null,
            padding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 40),
              child: _selectedWords.isEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tap the words below to build your sentence',
                        style: TextStyle(fontSize: 15, color: p.muted),
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final word in _selectedWords)
                          WordChip(
                            palette: p,
                            word: word,
                            inAnswer: true,
                            onTap: _answered ? null : () => _removeWord(word),
                          ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final word in _availableWords)
              WordChip(
                palette: p,
                word: word,
                onTap: _answered ? null : () => _selectWord(word),
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

class SentenceQuestion {
  final String targetSentence;
  final List<String> words;

  SentenceQuestion({
    required this.targetSentence,
    required this.words,
  });
}
