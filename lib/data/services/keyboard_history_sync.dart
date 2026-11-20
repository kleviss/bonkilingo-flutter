import '../../core/constants/language_constants.dart';
import '../data_sources/local/keyboard_history_queue.dart';
import '../models/chat_session_model.dart';
import '../repositories/correction_repository.dart';

/// Moves corrections made with the Bonkilingo keyboard into History.
///
/// Runs when the app starts and each time it comes back to the foreground.
/// Saving goes through [CorrectionRepository.saveChatSession], so signed-in
/// users get them in Supabase and guests in local storage, like corrections
/// made in the app.
class KeyboardHistorySync {
  final KeyboardHistoryQueue _queue;
  final CorrectionRepository _repository;
  Future<int>? _running;

  KeyboardHistorySync(this._queue, this._repository);

  /// Returns how many corrections were added. Overlapping calls share one run.
  Future<int> sync({required String? userId}) {
    return _running ??= _sync(userId ?? '').whenComplete(() => _running = null);
  }

  Future<int> _sync(String userId) async {
    final raw = await _queue.read();
    if (raw.isEmpty) return 0;

    final entries = KeyboardQueueEntry.parseQueue(raw);
    // Oldest first; History sorts newest first.
    for (final entry in entries) {
      await _repository.saveChatSession(
        userId: userId,
        correctedText: entry.corrected,
        inputText: entry.original,
        language: entry.language,
        model: LanguageConstants.defaultModel,
        source: ChatSessionModel.sourceKeyboard,
        createdAt: entry.createdAt,
        localId: 'kb-${entry.id}',
      );
    }
    // Only what was read: the keyboard may have added more meanwhile.
    await _queue.remove(KeyboardQueueEntry.rawIds(raw));
    return entries.length;
  }
}
