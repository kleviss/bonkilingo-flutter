import 'word_diff.dart';

/// Finds what a learner keeps getting corrected, from their recent
/// corrections, so Learn can suggest a lesson on it.
///
/// Each correction is split into changes with [wordDiff] (removed words →
/// added words), each change is sorted into a [MistakeKind], and kinds that
/// come up in at least [minCorrections] different corrections are returned,
/// most frequent first.

enum MistakeKind {
  article,
  preposition,
  verbForm,
  spelling,
  capitalization,
  punctuation,
}

/// One correction to learn from.
class CorrectionSample {
  final String original;
  final String corrected;

  /// An app language code (`english`, `german`, …) or `auto`.
  final String language;
  final DateTime? createdAt;

  const CorrectionSample({
    required this.original,
    required this.corrected,
    this.language = 'auto',
    this.createdAt,
  });
}

/// One change inside a correction: [removed] became [added]. Either side can
/// be empty (a word was only added or only removed).
class WordChange {
  final String removed;
  final String added;

  const WordChange(this.removed, this.added);

  @override
  bool operator ==(Object other) =>
      other is WordChange && other.removed == removed && other.added == added;

  @override
  int get hashCode => Object.hash(removed, added);

  @override
  String toString() => '"$removed" → "$added"';
}

/// A mistake that keeps coming back.
class MistakePattern {
  final MistakeKind kind;

  /// For [MistakeKind.spelling]: the correctly spelled word. Null when the
  /// pattern groups several misspelled words.
  final String? word;

  /// How many different corrections had this mistake.
  final int corrections;

  /// Up to three of the learner's own changes, newest first.
  final List<WordChange> examples;

  /// The most common language among those corrections (`auto` if unknown).
  final String language;

  const MistakePattern({
    required this.kind,
    required this.corrections,
    required this.examples,
    required this.language,
    this.word,
  });

  String get title {
    switch (kind) {
      case MistakeKind.article:
        return 'Articles';
      case MistakeKind.preposition:
        return 'Prepositions';
      case MistakeKind.verbForm:
        return 'Verb forms and endings';
      case MistakeKind.spelling:
        return word != null ? 'Spelling “$word”' : 'Spelling';
      case MistakeKind.capitalization:
        return 'Capital letters';
      case MistakeKind.punctuation:
        return 'Punctuation';
    }
  }

  /// What the lesson should teach, for the lesson prompt.
  String get topic {
    switch (kind) {
      case MistakeKind.article:
        return 'choosing the right article (definite, indefinite, gender and case where the language has them)';
      case MistakeKind.preposition:
        return 'choosing the right preposition';
      case MistakeKind.verbForm:
        return 'verb forms, tenses and word endings';
      case MistakeKind.spelling:
        return word != null
            ? 'spelling the word "$word" and similar words'
            : 'spelling words that are often misspelled';
      case MistakeKind.capitalization:
        return 'when to use capital letters';
      case MistakeKind.punctuation:
        return 'punctuation (commas, full stops, question marks, apostrophes)';
    }
  }

  /// The request for a short lesson on this mistake, built around the
  /// learner's own corrections.
  String get lessonPrompt {
    final languageName = language == 'auto'
        ? 'the language of the examples'
        : language[0].toUpperCase() + language.substring(1);
    final lines = [
      for (final e in examples)
        '- "${e.removed.isEmpty ? '(nothing)' : e.removed}" was corrected to '
            '"${e.added.isEmpty ? '(removed)' : e.added}"',
    ];
    return 'I am learning $languageName. In $corrections of my recent '
        'messages I was corrected on $topic. Some of my corrections:\n'
        '${lines.join('\n')}\n\n'
        'Teach me a short lesson on this in $languageName with explanations '
        'in English: 1) the rule in two or three sentences, 2) why my '
        'examples were wrong, 3) four correct example sentences, 4) a quiz of '
        'five fill-in-the-blank questions, with the answers at the end.';
  }
}

const _articles = {
  // English
  'a', 'an', 'the',
  // German
  'der', 'die', 'das', 'den', 'dem', 'des',
  'ein', 'eine', 'einen', 'einem', 'einer', 'eines',
  // Spanish
  'el', 'la', 'los', 'las', 'un', 'una', 'unos', 'unas',
  // French
  'le', 'les', 'une', "l'", 'l’',
  // Italian
  'il', 'lo', 'gli', 'uno',
  // Portuguese
  'o', 'os', 'as', 'um', 'uma', 'uns', 'umas',
};

const _prepositions = {
  // English
  'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'from', 'about', 'into',
  'onto', 'since',
  // German
  'an', 'auf', 'zu', 'zum', 'zur', 'für', 'mit', 'von', 'vom', 'bei', 'beim',
  'nach', 'aus', 'über', 'um', 'im', 'am', 'ins', 'seit',
  // Spanish
  'en', 'de', 'del', 'al', 'con', 'por', 'para', 'sobre', 'desde',
  // French
  'à', 'au', 'aux', 'dans', 'sur', 'pour', 'avec', 'par', 'chez', 'du',
  // Italian
  'di', 'da', 'su', 'per', 'tra', 'fra', 'nel', 'nella', 'alla', 'della',
  // Portuguese
  'em', 'no', 'na', 'do', 'ao', 'com', 'pelo', 'pela',
};

/// Forms of common auxiliary and irregular verbs (English and German), so
/// "is" → "are" or "habe" → "hatte" count as verb forms.
const _verbForms = {
  'am', 'is', 'are', 'was', 'were', 'be', 'been', 'being',
  'have', 'has', 'had', 'do', 'does', 'did', 'done',
  'go', 'goes', 'went', 'gone', 'get', 'gets', 'got', 'gotten',
  'bin', 'bist', 'ist', 'sind', 'seid', 'war', 'warst', 'waren', 'wart',
  'habe', 'hast', 'hat', 'haben', 'habt', 'hatte', 'hattest', 'hatten',
  'werde', 'wirst', 'wird', 'werden', 'werdet', 'wurde', 'wurden',
  'gehe', 'gehst', 'geht', 'gehen', 'ging', 'gingen', 'gegangen',
};

final _wordPattern = RegExp(r"[\p{L}\p{M}\p{N}'’]+", unicode: true);
final _hasLetterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

List<String> _words(String text) =>
    _wordPattern.allMatches(text).map((m) => m.group(0)!).toList();

/// The changes in one correction, in reading order.
List<WordChange> changesBetween(String original, String corrected) {
  final changes = <WordChange>[];
  var removed = StringBuffer();
  var added = StringBuffer();

  void flush() {
    final r = removed.toString().trim();
    final a = added.toString().trim();
    if (r.isNotEmpty || a.isNotEmpty) changes.add(WordChange(r, a));
    removed = StringBuffer();
    added = StringBuffer();
  }

  for (final part in wordDiff(original, corrected)) {
    switch (part.op) {
      case DiffOp.removed:
        removed.write(part.text);
      case DiffOp.added:
        added.write(part.text);
      case DiffOp.same:
        flush();
    }
  }
  flush();
  return changes;
}

/// What kind of mistake a change fixes, or null when it's a rewording that
/// doesn't fit a kind (those aren't suggested as lessons).
MistakeKind? classifyChange(WordChange change) {
  final removed = change.removed;
  final added = change.added;

  final removedHasWords = _hasLetterOrDigit.hasMatch(removed);
  final addedHasWords = _hasLetterOrDigit.hasMatch(added);
  if (!removedHasWords && !addedHasWords) return MistakeKind.punctuation;

  final removedWords = _words(removed);
  final addedWords = _words(added);
  // Same words, different punctuation around them ("Yes" → "Yes,").
  if (_sameList(removedWords, addedWords)) return MistakeKind.punctuation;

  final lowerRemoved = removedWords.map((w) => w.toLowerCase()).toList();
  final lowerAdded = addedWords.map((w) => w.toLowerCase()).toList();
  if (_sameList(lowerRemoved, lowerAdded)) return MistakeKind.capitalization;

  // Ignore words both sides share and look at what really differs.
  final onlyRemoved = [...lowerRemoved];
  final onlyAdded = <String>[];
  for (final word in lowerAdded) {
    if (!onlyRemoved.remove(word)) onlyAdded.add(word);
  }
  final differing = [...onlyRemoved, ...onlyAdded];
  if (differing.isEmpty) return null;

  if (differing.every(_articles.contains)) return MistakeKind.article;
  if (differing.every(_prepositions.contains)) return MistakeKind.preposition;

  if (onlyRemoved.length == 1 && onlyAdded.length == 1) {
    final from = onlyRemoved.single;
    final to = onlyAdded.single;
    if (_verbForms.contains(from) && _verbForms.contains(to)) {
      return MistakeKind.verbForm;
    }
    if (_differsOnlyInEnding(from, to)) return MistakeKind.verbForm;
    if (_isMisspelling(from, to)) return MistakeKind.spelling;
  }
  return null;
}

/// Recurring mistakes in [samples], most frequent first.
///
/// A misspelled word that comes back in [minCorrections] corrections gets
/// its own pattern; otherwise misspellings are grouped together.
List<MistakePattern> findMistakePatterns(
  List<CorrectionSample> samples, {
  int minCorrections = 2,
}) {
  // Newest first, so examples are the most recent ones.
  final sorted = [...samples]..sort((a, b) {
      final at = a.createdAt, bt = b.createdAt;
      if (at == null || bt == null) return 0;
      return bt.compareTo(at);
    });

  final groups = <String, _Group>{};
  _Group group(String key, MistakeKind kind, [String? word]) =>
      groups.putIfAbsent(key, () => _Group(kind, word));

  for (var i = 0; i < sorted.length; i++) {
    final sample = sorted[i];
    for (final change in changesBetween(sample.original, sample.corrected)) {
      final kind = classifyChange(change);
      if (kind == null) continue;
      group(kind.name, kind).add(i, change, sample.language);
      if (kind == MistakeKind.spelling) {
        final word = _words(change.added).first.toLowerCase();
        group('spelling:$word', kind, word).add(i, change, sample.language);
      }
    }
  }

  final patterns = <MistakePattern>[];
  final spellingWords = groups.values.where(
    (g) => g.word != null && g.corrections.length >= minCorrections,
  );
  for (final g in groups.values) {
    if (g.corrections.length < minCorrections) continue;
    // A word misspelled in at least half of the misspelling corrections is
    // a better lesson than "spelling" in general.
    if (g.kind == MistakeKind.spelling &&
        g.word == null &&
        spellingWords.any((w) => w.corrections.length * 2 >= g.corrections.length)) {
      continue;
    }
    patterns.add(g.toPattern());
  }

  patterns.sort((a, b) {
    final byScore = _score(b).compareTo(_score(a));
    if (byScore != 0) return byScore;
    return a.kind.index.compareTo(b.kind.index);
  });
  return patterns;
}

/// Grammar first: capital letters and punctuation are worth less of a lesson
/// than articles, verbs or a word the learner keeps misspelling.
double _score(MistakePattern p) {
  const weights = {
    MistakeKind.article: 1.0,
    MistakeKind.preposition: 1.0,
    MistakeKind.verbForm: 1.0,
    MistakeKind.spelling: 0.9,
    MistakeKind.punctuation: 0.6,
    MistakeKind.capitalization: 0.5,
  };
  final weight = p.kind == MistakeKind.spelling && p.word != null
      ? 1.1
      : weights[p.kind]!;
  return p.corrections * weight;
}

class _Group {
  final MistakeKind kind;
  final String? word;
  final corrections = <int>{};
  final examples = <WordChange>[];
  final languages = <String, int>{};

  _Group(this.kind, this.word);

  void add(int correction, WordChange change, String language) {
    if (corrections.add(correction)) {
      languages[language] = (languages[language] ?? 0) + 1;
    }
    if (examples.length < 3 && !examples.contains(change)) examples.add(change);
  }

  MistakePattern toPattern() {
    final known = languages.entries.where((e) => e.key != 'auto').toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return MistakePattern(
      kind: kind,
      word: word,
      corrections: corrections.length,
      examples: List.unmodifiable(examples),
      language: known.isEmpty ? 'auto' : known.first.key,
    );
  }
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

int _commonPrefix(String a, String b) {
  var i = 0;
  while (i < a.length && i < b.length && a[i] == b[i]) {
    i++;
  }
  return i;
}

/// "walk" → "walked", "gehe" → "gehen", "lives" → "lived": the same stem
/// with a different ending of up to three letters. Short pairs like
/// "their" → "there" only count when one word is the stem itself.
bool _differsOnlyInEnding(String a, String b) {
  final prefix = _commonPrefix(a, b);
  final restA = a.length - prefix;
  final restB = b.length - prefix;
  if (prefix < 3 || restA > 3 || restB > 3) return false;
  return prefix >= 4 || restA == 0 || restB == 0;
}

/// A small edit (at most two letters, or a quarter of the word).
bool _isMisspelling(String a, String b) {
  final longer = a.length > b.length ? a.length : b.length;
  if (longer < 3) return false;
  final allowed = longer >= 8 ? (longer / 4).floor() : 2;
  return _editDistance(a, b) <= allowed;
}

int _editDistance(String a, String b) {
  var previous = List<int>.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0)..[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      final best = previous[j] + 1 < current[j - 1] + 1
          ? previous[j] + 1
          : current[j - 1] + 1;
      current[j] = best < previous[j - 1] + cost ? best : previous[j - 1] + cost;
    }
    previous = current;
  }
  return previous[b.length];
}
