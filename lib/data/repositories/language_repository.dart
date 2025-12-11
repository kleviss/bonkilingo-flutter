import '../data_sources/remote/ai_api.dart';
import '../models/language_detection.dart';

class LanguageRepository {
  final AIApi _aiApi;

  LanguageRepository(this._aiApi);

  /// Detect language of input text
  Future<String?> detectLanguage(String text) async {
    try {
      final request = LanguageDetectionRequest(text: text);
      final response = await _aiApi.detectLanguage(request);
      
      if (response.language == 'unknown') {
        return null;
      }
      
      return response.language;
    } catch (e) {
      print('Failed to detect language: $e');
      return null;
    }
  }
}

