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

    // Show feedback
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(isCorrect ? 'Correct!' : 'Try Again'),
        content: Text(
          isCorrect
              ? 'Great job! You constructed the sentence correctly.'
              : 'The correct sentence is: "${question.targetSentence}"',
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
    final themeMode = ref.watch(themeModeProvider);
    final theme = ThemeHelper(themeMode);

    if (_isLoading) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Sentence Construction'),
        ),
        child: const Center(child: CupertinoActivityIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Sentence Construction'),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.construction,
                    size: 64, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'No words available',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete some text corrections to generate sentence construction exercises.',
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
        middle: Text('Sentence Construction'),
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

          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Construct a sentence using these words:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: question.words
                      .map((word) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: theme.primary.withOpacity(0.3)),
                            ),
                            child: Text(
                              word,
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Selected words
          if (_selectedWords.isNotEmpty) ...[
            Text(
              'Your sentence:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.border),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedWords
                    .map((word) => GestureDetector(
                          onTap: () => _removeWord(word),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  word,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: CupertinoColors.white,
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Available words
          Text(
            'Available words:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableWords
                .map((word) => GestureDetector(
                      onTap: () => _selectWord(word),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: theme.cardBackground,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.border),
                        ),
                        child: Text(
                          word,
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textPrimary,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),

          // Check button
          CupertinoButton.filled(
            onPressed: _selectedWords.isEmpty ? null : _checkAnswer,
            child: const Text('Check Answer'),
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

class SentenceQuestion {
  final String targetSentence;
  final List<String> words;

  SentenceQuestion({
    required this.targetSentence,
    required this.words,
  });
}
