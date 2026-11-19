class LanguageConstants {
  static const List<Language> supportedLanguages = [
    Language(code: 'english', name: 'English'),
    Language(code: 'spanish', name: 'Spanish'),
    Language(code: 'french', name: 'French'),
    Language(code: 'german', name: 'German'),
    Language(code: 'italian', name: 'Italian'),
    Language(code: 'portuguese', name: 'Portuguese'),
  ];

  static const List<AIModel> availableModels = [
    AIModel(value: 'gpt-6-luna', label: 'GPT-6 Luna'),
    AIModel(value: 'gpt-6.1-terra', label: 'GPT-6.1 Terra'),
  ];

  static const String defaultLanguage = 'english';
  static const String defaultModel = 'gpt-6-luna';

  LanguageConstants._();
}

class Language {
  final String code;
  final String name;

  const Language({
    required this.code,
    required this.name,
  });
}

class AIModel {
  final String value;
  final String label;

  const AIModel({
    required this.value,
    required this.label,
  });
}

