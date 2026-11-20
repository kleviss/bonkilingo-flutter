import 'package:flutter/services.dart';

import 'keyboard_settings.dart';

/// A correction made with the Bonkilingo keyboard, waiting to be added to
/// History.
///
/// The keyboard writes these to the App Group
/// (`ios/BonkilingoKeyboard/Settings.swift`, `KeyboardHistoryQueue`) and
/// `ios/Runner/AppDelegate.swift` hands them to Flutter.
class KeyboardQueueEntry {
  final String id;
  final String original;
  final String corrected;
  final DateTime createdAt;

  /// An app language code (`english`, `german`, …), or `auto` when the
  /// language wasn't detected or isn't one the app supports.
  final String language;

  const KeyboardQueueEntry({
    required this.id,
    required this.original,
    required this.corrected,
    required this.createdAt,
    required this.language,
  });

  /// Parses one queued entry, or returns null if it is malformed.
  static KeyboardQueueEntry? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final original = raw['original'];
    final corrected = raw['corrected'];
    final timestamp = raw['timestamp'];
    if (id is! String || id.isEmpty) return null;
    if (original is! String || original.trim().isEmpty) return null;
    if (corrected is! String || corrected.trim().isEmpty) return null;
    if (timestamp is! num) return null;

    final code = raw['languageCode'];
    return KeyboardQueueEntry(
      id: id,
      original: original,
      corrected: corrected,
      createdAt: DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()),
      language: languageFromIsoCode(code is String ? code : null),
    );
  }

  /// Parses the whole queue, skipping malformed entries and duplicate ids,
  /// oldest first.
  static List<KeyboardQueueEntry> parseQueue(Object? raw) {
    if (raw is! List) return const [];
    final seen = <String>{};
    final entries = <KeyboardQueueEntry>[];
    for (final item in raw) {
      final entry = tryParse(item);
      if (entry != null && seen.add(entry.id)) entries.add(entry);
    }
    entries.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return entries;
  }

  /// Ids of every entry in the raw queue that has one, malformed or not, so
  /// unreadable entries are removed too instead of being retried forever.
  static List<String> rawIds(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map && item['id'] is String) item['id'] as String,
    ];
  }
}

/// Maps an ISO 639 code (as iOS's language recognizer returns it, e.g. `de`
/// or `pt-BR`) to the app's language codes.
String languageFromIsoCode(String? code) {
  if (code == null) return 'auto';
  final base = code.toLowerCase().split(RegExp('[-_]')).first;
  const names = {
    'en': 'english',
    'es': 'spanish',
    'fr': 'french',
    'de': 'german',
    'it': 'italian',
    'pt': 'portuguese',
  };
  return names[base] ?? 'auto';
}

/// Reads and acknowledges the keyboard's queue through the native channel.
class KeyboardHistoryQueue {
  static const _channel = MethodChannel('com.bonkilingo.app/keyboard_settings');

  /// The raw queue, as the native side returns it.
  Future<List<Object?>> read() async {
    if (!KeyboardSettings.isSupported) return const [];
    final raw = await _channel.invokeMethod<List<Object?>>('readHistoryQueue');
    return raw ?? const [];
  }

  /// Removes the given entries from the queue.
  Future<void> remove(List<String> ids) async {
    if (!KeyboardSettings.isSupported || ids.isEmpty) return;
    await _channel.invokeMethod<void>('removeHistoryEntries', {'ids': ids});
  }
}
