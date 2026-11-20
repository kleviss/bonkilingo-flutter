import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/mistake_patterns.dart';
import '../../providers/chat_history_provider.dart';

/// How many recent corrections are looked at for suggestions.
const _recentCorrections = 50;

/// What the learner keeps getting corrected, most frequent first
/// (Learn → Suggested for you).
final mistakePatternsProvider =
    FutureProvider.autoDispose<List<MistakePattern>>((ref) async {
  final history = await ref.watch(chatHistoryProvider.future);
  final samples = history
      .take(_recentCorrections)
      .map(
        (session) => CorrectionSample(
          original: session.inputText,
          corrected: session.correctedText,
          language: session.language,
          createdAt: session.createdAt,
        ),
      )
      .toList();
  return findMistakePatterns(samples);
});
