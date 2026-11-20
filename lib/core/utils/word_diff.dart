/// Word-level diff between an original and a corrected text, used to mark
/// what was removed (red) and what was added (green).

enum DiffOp { same, removed, added }

class DiffPart {
  final DiffOp op;
  final String text;
  const DiffPart(this.op, this.text);
}

/// Above this many tokens per side the diff is skipped (it is O(n·m)) and
/// the whole text is returned as one changed block.
const _maxTokens = 600;

// Whitespace, words (letters, marks, digits, apostrophes; any script), or a
// single punctuation mark, so "Yesterday" → "Yesterday," only marks the comma.
final _tokenPattern = RegExp(
  r"\s+|[\p{L}\p{M}\p{N}'’]+|[^\s\p{L}\p{M}\p{N}'’]",
  unicode: true,
);

List<String> _tokenize(String s) =>
    _tokenPattern.allMatches(s).map((m) => m.group(0)!).toList();

/// Returns the parts in reading order: removed parts belong to the original,
/// added parts to the corrected text, same parts to both.
List<DiffPart> wordDiff(String original, String corrected) {
  final a = _tokenize(original);
  final b = _tokenize(corrected);

  if (a.length > _maxTokens || b.length > _maxTokens) {
    return [
      if (original.isNotEmpty) DiffPart(DiffOp.removed, original),
      if (corrected.isNotEmpty) DiffPart(DiffOp.added, corrected),
    ];
  }

  // Longest common subsequence table, filled from the end.
  final lcs = List.generate(a.length + 1, (_) => List.filled(b.length + 1, 0));
  for (var i = a.length - 1; i >= 0; i--) {
    for (var j = b.length - 1; j >= 0; j--) {
      lcs[i][j] = a[i] == b[j]
          ? lcs[i + 1][j + 1] + 1
          : (lcs[i + 1][j] >= lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1]);
    }
  }

  final parts = <DiffPart>[];
  void add(DiffOp op, String text) {
    if (parts.isNotEmpty && parts.last.op == op) {
      parts[parts.length - 1] = DiffPart(op, parts.last.text + text);
    } else {
      parts.add(DiffPart(op, text));
    }
  }

  var i = 0, j = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      add(DiffOp.same, a[i]);
      i++;
      j++;
    } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
      add(DiffOp.removed, a[i++]);
    } else {
      add(DiffOp.added, b[j++]);
    }
  }
  while (i < a.length) {
    add(DiffOp.removed, a[i++]);
  }
  while (j < b.length) {
    add(DiffOp.added, b[j++]);
  }
  return parts;
}
