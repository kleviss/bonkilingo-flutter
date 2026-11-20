import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_history_provider.dart';

/// Adds corrections made with the Bonkilingo keyboard to History when the
/// app starts and whenever it comes back to the foreground.
class KeyboardHistorySyncObserver extends ConsumerStatefulWidget {
  final Widget child;

  const KeyboardHistorySyncObserver({required this.child, super.key});

  @override
  ConsumerState<KeyboardHistorySyncObserver> createState() =>
      _KeyboardHistorySyncObserverState();
}

class _KeyboardHistorySyncObserverState
    extends ConsumerState<KeyboardHistorySyncObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _sync();
  }

  Future<void> _sync() async {
    try {
      final userId = ref.read(currentUserProvider).value?.id;
      final added =
          await ref.read(keyboardHistorySyncProvider).sync(userId: userId);
      if (added > 0 && mounted) ref.invalidate(chatHistoryProvider);
    } catch (e) {
      // The queue stays in the App Group and is retried next time.
      debugPrint('Keyboard history sync failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
