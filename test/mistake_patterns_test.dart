import 'package:bonkilingo/core/utils/mistake_patterns.dart';
import 'package:flutter_test/flutter_test.dart';

CorrectionSample s(String original, String corrected, {String language = 'english', int day = 1}) =>
    CorrectionSample(
      original: original,
      corrected: corrected,
      language: language,
      createdAt: DateTime(2026, 11, day),
    );

void main() {
  group('changesBetween', () {
    test('splits a correction into word changes', () {
      expect(changesBetween('I has a apple', 'I have an apple'), const [
        WordChange('has', 'have'),
        WordChange('a', 'an'),
      ]);
    });

    test('keeps added-only and removed-only changes', () {
      expect(changesBetween('I go store', 'I go to the store'), const [WordChange('', 'to the')]);
      expect(changesBetween('He is is here', 'He is here'), const [WordChange('is', '')]);
    });

    test('no changes for identical text', () {
      expect(changesBetween('All good.', 'All good.'), isEmpty);
    });
  });

  group('classifyChange', () {
    test('articles', () {
      expect(classifyChange(const WordChange('a', 'an')), MistakeKind.article);
      expect(classifyChange(const WordChange('der', 'die')), MistakeKind.article);
      expect(classifyChange(const WordChange('', 'the')), MistakeKind.article);
    });

    test('prepositions', () {
      expect(classifyChange(const WordChange('in', 'on')), MistakeKind.preposition);
      expect(classifyChange(const WordChange('für', 'mit')), MistakeKind.preposition);
    });

    test('verb forms and endings', () {
      expect(classifyChange(const WordChange('has', 'have')), MistakeKind.verbForm);
      expect(classifyChange(const WordChange('go', 'went')), MistakeKind.verbForm);
      expect(classifyChange(const WordChange('walk', 'walked')), MistakeKind.verbForm);
      expect(classifyChange(const WordChange('gehe', 'gehen')), MistakeKind.verbForm);
    });

    test('spelling', () {
      expect(classifyChange(const WordChange('recieve', 'receive')), MistakeKind.spelling);
      expect(classifyChange(const WordChange('definately', 'definitely')), MistakeKind.spelling);
      expect(classifyChange(const WordChange('their', 'there')), MistakeKind.spelling);
    });

    test('capitalization and punctuation', () {
      expect(classifyChange(const WordChange('monday', 'Monday')), MistakeKind.capitalization);
      expect(classifyChange(const WordChange('', ',')), MistakeKind.punctuation);
      expect(classifyChange(const WordChange('dont', "don't")), MistakeKind.spelling);
    });

    test('rewording is not a pattern', () {
      expect(classifyChange(const WordChange('big', 'enormous')), isNull);
      expect(classifyChange(const WordChange('I think that', 'In my opinion')), isNull);
    });
  });

  group('findMistakePatterns', () {
    test('returns the most frequent mistake first', () {
      final patterns = findMistakePatterns([
        s('I ate a apple', 'I ate an apple', day: 1),
        s('She is a honest person', 'She is an honest person', day: 2),
        s('I go to the school', 'I go to school', day: 3),
        s('We meet in Monday', 'We meet on Monday', day: 4),
      ]);
      expect(patterns.first.kind, MistakeKind.article);
      expect(patterns.first.corrections, 3);
      // Newest example first.
      expect(patterns.first.examples.first, const WordChange('the', ''));
      expect(patterns.first.language, 'english');
      // Prepositions only came up once.
      expect(patterns.any((p) => p.kind == MistakeKind.preposition), isFalse);
    });

    test('a word misspelled again and again gets its own pattern', () {
      final patterns = findMistakePatterns([
        s('I recieve mail', 'I receive mail'),
        s('Did you recieve it?', 'Did you receive it?'),
        s('We recieved it', 'We received it'),
      ]);
      // "recieved" → "received" groups with its stem under spelling.
      final spelling = patterns.firstWhere((p) => p.kind == MistakeKind.spelling);
      expect(spelling.word, 'receive');
      expect(spelling.title, 'Spelling “receive”');
      expect(spelling.corrections, 2);
      expect(patterns.where((p) => p.kind == MistakeKind.spelling), hasLength(1));
    });

    test('different misspelled words group as spelling', () {
      final patterns = findMistakePatterns([
        s('I recieve mail', 'I receive mail'),
        s('It is definately here', 'It is definitely here'),
        s('See you tommorow', 'See you tomorrow'),
      ]);
      expect(patterns.single.kind, MistakeKind.spelling);
      expect(patterns.single.word, isNull);
      expect(patterns.single.corrections, 3);
    });

    test('counts a correction once even with several of the same mistake', () {
      final patterns = findMistakePatterns([
        s('a apple and a orange', 'an apple and an orange'),
      ]);
      expect(patterns, isEmpty);
    });

    test('grammar ranks above punctuation with the same count', () {
      final patterns = findMistakePatterns([
        s('Yes I has it', 'Yes, I have it'),
        s('Well she have time', 'Well, she has time'),
      ]);
      expect(patterns.map((p) => p.kind), [MistakeKind.verbForm, MistakeKind.punctuation]);
    });

    test('picks the most common known language', () {
      final patterns = findMistakePatterns([
        s('Ich habe der Hund', 'Ich habe den Hund', language: 'german'),
        s('Das ist die Tisch', 'Das ist der Tisch', language: 'auto'),
      ]);
      expect(patterns.single.kind, MistakeKind.article);
      expect(patterns.single.language, 'german');
    });

    test('nothing to suggest without repeated mistakes', () {
      expect(findMistakePatterns([]), isEmpty);
      expect(findMistakePatterns([s('Hello', 'Hello')]), isEmpty);
    });
  });

  test('lessonPrompt names the language, topic and the learner\'s examples', () {
    const pattern = MistakePattern(
      kind: MistakeKind.article,
      corrections: 3,
      examples: [WordChange('der', 'den'), WordChange('', 'die')],
      language: 'german',
    );
    final prompt = pattern.lessonPrompt;
    expect(prompt, contains('I am learning German'));
    expect(prompt, contains('In 3 of my recent messages'));
    expect(prompt, contains('"der" was corrected to "den"'));
    expect(prompt, contains('"(nothing)" was corrected to "die"'));
    expect(prompt, contains('quiz'));
  });
}
