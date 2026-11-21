import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/keyboard_auth_service.dart';
import '../providers/auth_provider.dart';
import '../providers/providers.dart';

final keyboardAuthServiceProvider = Provider<KeyboardAuthService>((ref) {
  return KeyboardAuthService(ref.watch(dioClientProvider));
});

/// Keeps the Bonkilingo keyboard signed in as the same user as the app:
/// on start, on every sign-in/sign-out, and when the app returns to the
/// foreground (in case an earlier attempt failed offline).
class KeyboardAuthObserver extends ConsumerStatefulWidget {
  final Widget child;

  const KeyboardAuthObserver({required this.child, super.key});

  @override
  ConsumerState<KeyboardAuthObserver> createState() =>
      _KeyboardAuthObserverState();
}

class _KeyboardAuthObserverState extends ConsumerState<KeyboardAuthObserver>
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
    final userId = ref.read(currentUserProvider).value?.id;
    try {
      await ref.read(keyboardAuthServiceProvider).sync(userId: userId);
    } catch (e) {
      // Retried on the next sign-in change or when the app comes back.
      debugPrint('Keyboard sign-in sync failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(currentUserProvider, (previous, next) {
      if (previous?.value?.id != next.value?.id) _sync();
    });
    return widget.child;
  }
}
