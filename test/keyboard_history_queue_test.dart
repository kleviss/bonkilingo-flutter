import 'package:bonkilingo/data/data_sources/local/keyboard_history_queue.dart';
import 'package:bonkilingo/data/models/chat_session_model.dart';
import 'package:bonkilingo/data/repositories/correction_repository.dart';
import 'package:bonkilingo/data/services/keyboard_history_sync.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, Object?> entry(String id, {int timestamp = 1700000000000, String? languageCode}) => {
      'id': id,
      'original': 'I has a apple',
      'corrected': 'I have an apple',
      'timestamp': timestamp,
      if (languageCode != null) 'languageCode': languageCode,
    };

class FakeQueue implements KeyboardHistoryQueue {
  List<Object?> items;
  final removed = <String>[];
  FakeQueue(this.items);

  @override
  Future<List<Object?>> read() async => items;

  @override
  Future<void> remove(List<String> ids) async => removed.addAll(ids);
}

class FakeRepository implements CorrectionRepository {
  final saved = <Map<String, Object?>>[];

  @override
  Future<void> saveChatSession({
    required String userId,
    required String correctedText,
    required String inputText,
    required String language,
    required String model,
    String source = ChatSessionModel.sourceApp,
    DateTime? createdAt,
    String? localId,
  }) async {
    saved.add({
      'userId': userId,
      'inputText': inputText,
      'source': source,
      'createdAt': createdAt,
      'localId': localId,
      'language': language,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('KeyboardQueueEntry.tryParse', () {
    test('reads a queued correction', () {
      final parsed = KeyboardQueueEntry.tryParse(entry('a', languageCode: 'de'))!;
      expect(parsed.id, 'a');
      expect(parsed.original, 'I has a apple');
      expect(parsed.corrected, 'I have an apple');
      expect(parsed.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(parsed.language, 'german');
    });

    test('accepts a double timestamp (NSNumber from Swift)', () {
      final parsed = KeyboardQueueEntry.tryParse({...entry('a'), 'timestamp': 1700000000000.0});
      expect(parsed?.createdAt.millisecondsSinceEpoch, 1700000000000);
    });

    test('uses auto when the language is missing or unsupported', () {
      expect(KeyboardQueueEntry.tryParse(entry('a'))!.language, 'auto');
      expect(KeyboardQueueEntry.tryParse(entry('a', languageCode: 'ja'))!.language, 'auto');
    });

    test('rejects malformed entries', () {
      expect(KeyboardQueueEntry.tryParse(null), isNull);
      expect(KeyboardQueueEntry.tryParse('text'), isNull);
      expect(KeyboardQueueEntry.tryParse({...entry('a'), 'id': ''}), isNull);
      expect(KeyboardQueueEntry.tryParse({...entry('a'), 'original': '  '}), isNull);
      expect(KeyboardQueueEntry.tryParse({...entry('a'), 'corrected': null}), isNull);
      expect(KeyboardQueueEntry.tryParse({...entry('a'), 'timestamp': '2024'}), isNull);
    });
  });

  group('KeyboardQueueEntry.parseQueue', () {
    test('skips bad entries and duplicate ids, oldest first', () {
      final parsed = KeyboardQueueEntry.parseQueue([
        entry('new', timestamp: 3000),
        {'id': 'broken'},
        entry('old', timestamp: 1000),
        entry('new', timestamp: 3000),
      ]);
      expect(parsed.map((e) => e.id), ['old', 'new']);
    });

    test('returns nothing for a non-list', () {
      expect(KeyboardQueueEntry.parseQueue(null), isEmpty);
      expect(KeyboardQueueEntry.parseQueue({'id': 'a'}), isEmpty);
    });

    test('rawIds includes malformed entries so they get removed', () {
      expect(KeyboardQueueEntry.rawIds([entry('a'), {'id': 'broken'}, 'junk']), ['a', 'broken']);
    });
  });

  test('languageFromIsoCode maps ISO codes to app languages', () {
    expect(languageFromIsoCode('en'), 'english');
    expect(languageFromIsoCode('pt-BR'), 'portuguese');
    expect(languageFromIsoCode('zh-Hans'), 'auto');
    expect(languageFromIsoCode(null), 'auto');
  });

  group('KeyboardHistorySync', () {
    test('saves entries as keyboard corrections and removes what it read', () async {
      final queue = FakeQueue([
        entry('b', timestamp: 2000, languageCode: 'en'),
        entry('a', timestamp: 1000),
        {'id': 'broken'},
      ]);
      final repository = FakeRepository();
      final added = await KeyboardHistorySync(queue, repository).sync(userId: 'user-1');

      expect(added, 2);
      expect(repository.saved.map((s) => s['localId']), ['kb-a', 'kb-b']);
      expect(repository.saved.every((s) => s['source'] == ChatSessionModel.sourceKeyboard), isTrue);
      expect(repository.saved.first['createdAt'], DateTime.fromMillisecondsSinceEpoch(1000));
      expect(repository.saved.last['language'], 'english');
      expect(repository.saved.first['userId'], 'user-1');
      expect(queue.removed, ['b', 'a', 'broken']);
    });

    test('guests save with an empty user id', () async {
      final repository = FakeRepository();
      await KeyboardHistorySync(FakeQueue([entry('a')]), repository).sync(userId: null);
      expect(repository.saved.single['userId'], '');
    });

    test('does nothing for an empty queue', () async {
      final queue = FakeQueue([]);
      final repository = FakeRepository();
      expect(await KeyboardHistorySync(queue, repository).sync(userId: null), 0);
      expect(queue.removed, isEmpty);
      expect(repository.saved, isEmpty);
    });
  });
}
