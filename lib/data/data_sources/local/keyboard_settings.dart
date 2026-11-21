import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Settings the Bonkilingo keyboard reads, and setup helpers for it.
///
/// iOS: stored natively in the App Group defaults (`ios/Runner/AppDelegate.swift`)
/// because the keyboard extension runs in its own process and can't read the
/// app's SharedPreferences. Android: the keyboard is an input method service
/// in the app's own package (`android/.../keyboard/BonkilingoKeyboardService.kt`),
/// and `MainActivity.kt` answers the same channel.
class KeyboardSettings {
  static const _channel = MethodChannel('com.bonkilingo.app/keyboard_settings');

  /// Must match the key the keyboard extension reads.
  static const correctionsEnabledKey = 'keyboard.correctionsEnabled';
  static const saveToHistoryKey = 'keyboard.saveToHistory';

  /// The keyboard exists on iOS and Android.
  static bool get isSupported => isIOS || isAndroid;

  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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

  /// Whether the keyboard keeps its corrections for History. On by default.
  Future<bool> getSaveToHistory() => _getBool(saveToHistoryKey, true);

  Future<void> setSaveToHistory(bool enabled) =>
      _setBool(saveToHistoryKey, enabled);

  Future<bool> _getBool(String key, bool defaultValue) async {
    if (!isSupported) return defaultValue;
    final value = await _channel.invokeMethod<bool>('getBool', {
      'key': key,
      'defaultValue': defaultValue,
    });
    return value ?? defaultValue;
  }

  Future<void> _setBool(String key, bool value) async {
    if (!isSupported) return;
    await _channel.invokeMethod<void>('setBool', {'key': key, 'value': value});
  }

  /// Android: whether the Bonkilingo keyboard is turned on in system settings
  /// and whether it is the keyboard in use. Null elsewhere.
  Future<KeyboardStatus?> getStatus() async {
    if (!isAndroid) return null;
    final value = await _channel.invokeMapMethod<String, bool>('keyboardStatus');
    return KeyboardStatus(
      enabled: value?['enabled'] ?? false,
      selected: value?['selected'] ?? false,
    );
  }

  /// Android: opens the system screen where keyboards are turned on.
  Future<void> openSystemKeyboardSettings() async {
    if (!isAndroid) return;
    await _channel.invokeMethod<void>('openKeyboardSettings');
  }

  /// Android: shows the system's keyboard picker.
  Future<void> showKeyboardPicker() async {
    if (!isAndroid) return;
    await _channel.invokeMethod<void>('showKeyboardPicker');
  }

  /// Android: hands the signed-in user's keyboard token to the keyboard
  /// (iOS shares it through the Keychain instead). Null signs it out.
  Future<void> setKeyboardToken(String? token) async {
    if (!isAndroid) return;
    await _channel.invokeMethod<void>('setKeyboardToken', {'token': token});
  }
}

class KeyboardStatus {
  final bool enabled;
  final bool selected;

  const KeyboardStatus({required this.enabled, required this.selected});
}
