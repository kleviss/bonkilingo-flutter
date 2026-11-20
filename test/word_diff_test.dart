import 'package:bonkilingo/core/utils/word_diff.dart';
import 'package:flutter_test/flutter_test.dart';

String _side(List<DiffPart> parts, DiffOp keep) =>
    parts.where((p) => p.op == DiffOp.same || p.op == keep).map((p) => p.text).join();

void main() {
  test('marks a replaced word as removed and added', () {
    final parts = wordDiff('I goed to the store.', 'I went to the store.');
    expect(parts.where((p) => p.op == DiffOp.removed).single.text, 'goed');
    expect(parts.where((p) => p.op == DiffOp.added).single.text, 'went');
  });

  test('each side rebuilds its own text exactly', () {
    const a = 'She dont like\napples ,really.';
    const b = "She doesn't like\napples, really.";
    final parts = wordDiff(a, b);
    expect(_side(parts, DiffOp.removed), a);
    expect(_side(parts, DiffOp.added), b);
  });

  test('an added comma does not mark the word before it', () {
    final parts = wordDiff('Yesterday I went.', 'Yesterday, I went.');
    expect(parts.where((p) => p.op == DiffOp.added).single.text, ',');
    expect(parts.where((p) => p.op == DiffOp.removed), isEmpty);
  });

  test('accented words stay whole', () {
    final parts = wordDiff('Ich möchte gehen.', 'Ich möchte laufen.');
    expect(parts.where((p) => p.op == DiffOp.removed).single.text, 'gehen');
  });

  test('identical text has only unchanged parts', () {
    final parts = wordDiff('All good here.', 'All good here.');
    expect(parts.every((p) => p.op == DiffOp.same), isTrue);
  });

  test('empty original marks everything as added', () {
    final parts = wordDiff('', 'Hello there');
    expect(parts.every((p) => p.op == DiffOp.added), isTrue);
    expect(_side(parts, DiffOp.added), 'Hello there');
  });
}
