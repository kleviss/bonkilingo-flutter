import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Settings the Bonkilingo keyboard extension reads.
///
/// Stored natively in the App Group defaults (`group.com.bonkilingo.app`, see
/// `ios/Runner/AppDelegate.swift`) because the keyboard runs in its own
/// process and can't read the app's SharedPreferences.
class KeyboardSettings {
  static const _channel = MethodChannel('com.bonkilingo.app/keyboard_settings');

  /// Must match the key the keyboard extension reads.
  static const correctionsEnabledKey = 'keyboard.correctionsEnabled';

  /// The keyboard only exists on iOS.
  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Whether the keyboard shows its Correct button. On by default.
  Future<bool> getCorrectionsEnabled() async {
    if (!isSupported) return true;
    final value = await _channel.invokeMethod<bool>('getBool', {
      'key': correctionsEnabledKey,
      'defaultValue': true,
    });
    return value ?? true;
  }

  Future<void> setCorrectionsEnabled(bool enabled) async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('setBool', {
      'key': correctionsEnabledKey,
      'value': enabled,
    });
  }
}
