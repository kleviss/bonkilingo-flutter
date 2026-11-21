import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/data_sources/local/keyboard_settings.dart';

final keyboardSettingsProvider = Provider<KeyboardSettings>((ref) {
  return KeyboardSettings();
});

/// Whether the Bonkilingo keyboard shows its Correct button.
/// `null` while the stored value loads.
final keyboardCorrectionsEnabledProvider =
    StateNotifierProvider<KeyboardCorrectionsNotifier, bool?>((ref) {
  return KeyboardCorrectionsNotifier(ref.watch(keyboardSettingsProvider));
});

class KeyboardCorrectionsNotifier extends StateNotifier<bool?> {
  final KeyboardSettings _settings;

  KeyboardCorrectionsNotifier(this._settings) : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final enabled = await _settings.getCorrectionsEnabled();
      if (mounted) state = enabled;
    } catch (_) {
      if (mounted) state = true;
    }
  }

  /// Switches immediately, then saves; reverts if saving fails.
  Future<void> setEnabled(bool enabled) async {
    final previous = state;
    state = enabled;
    try {
      await _settings.setCorrectionsEnabled(enabled);
    } catch (_) {
      if (mounted) state = previous;
    }
  }
}

/// Whether the keyboard keeps its corrections for History.
/// `null` while the stored value loads.
final keyboardSaveToHistoryProvider =
    StateNotifierProvider<KeyboardSaveToHistoryNotifier, bool?>((ref) {
  return KeyboardSaveToHistoryNotifier(ref.watch(keyboardSettingsProvider));
});

class KeyboardSaveToHistoryNotifier extends StateNotifier<bool?> {
  final KeyboardSettings _settings;

  KeyboardSaveToHistoryNotifier(this._settings) : super(null) {
    _load();
  }

  Future<void> _load() async {
    try {
      final enabled = await _settings.getSaveToHistory();
      if (mounted) state = enabled;
    } catch (_) {
      if (mounted) state = true;
    }
  }

  /// Switches immediately, then saves; reverts if saving fails.
  Future<void> setEnabled(bool enabled) async {
    final previous = state;
    state = enabled;
    try {
      await _settings.setSaveToHistory(enabled);
    } catch (_) {
      if (mounted) state = previous;
    }
  }
}
