import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/data_sources/local/keyboard_history_queue.dart';
import '../../data/models/chat_session_model.dart';
import '../../data/services/keyboard_history_sync.dart';
import 'auth_provider.dart';
import 'providers.dart';

/// The user's corrections, newest first (History, Learn suggestions).
/// Reloaded each time History opens; Learn reloads it when its tab is shown.
final chatHistoryProvider =
    FutureProvider.autoDispose<List<ChatSessionModel>>((ref) async {
  final correctionRepository = ref.watch(correctionRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider).value;

  return await correctionRepository.getChatHistory(currentUser?.id);
});

final keyboardHistorySyncProvider = Provider<KeyboardHistorySync>((ref) {
  return KeyboardHistorySync(
    KeyboardHistoryQueue(),
    ref.watch(correctionRepositoryProvider),
  );
});
