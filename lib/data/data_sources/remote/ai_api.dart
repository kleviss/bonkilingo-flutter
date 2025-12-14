import 'package:dio/dio.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_exception.dart';
import '../../models/correction_request.dart';
import '../../models/lesson_request.dart';
import '../../models/language_detection.dart';

class AIApi {
  final DioClient _dioClient;

  AIApi(this._dioClient);

  /// Correct text using AI
  Future<CorrectionResponse> correctText(CorrectionRequest request) async {
    try {
      final response = await _dioClient.post(
        AppConstants.correctEndpoint,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return CorrectionResponse.fromJson(response.data);
      } else {
        throw ApiException(
          message: 'Failed to correct text',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout. Please check your internet.');
      } else if (e.type == DioExceptionType.unknown) {
        throw NetworkException('No internet connection');
      } else {
        throw ServerException(e.message ?? 'Server error occurred');
      }
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Generate a tiny lesson based on situation
  Future<LessonResponse> generateLesson(LessonRequest request) async {
    try {
      final systemPrompt =
          'You are a helpful language tutor. Provide relevant vocabulary, useful phrases, and grammar tips for the situation described by the user. Format your response in three clear sections: 1) Key Vocabulary (10-15 relevant words with translations), 2) Useful Phrases (5-8 practical expressions with translations), and 3) Grammar Tips (2-3 relevant grammar points with simple examples). Keep your response concise and focused on practical language use.';

      final response = await _dioClient.post(
        AppConstants.chatEndpoint,
        data: {
          'messages': [
            {
              'role': 'user',
              'content':
                  'I need vocabulary, phrases, and grammar tips for this situation in ${request.language}: ${request.situation}',
            },
          ],
          'model': request.model,
          'systemPrompt': systemPrompt,
        },
      );

      if (response.statusCode == 200) {
        return LessonResponse.fromJson(response.data);
      } else {
        throw ApiException(
          message: 'Failed to generate lesson',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout. Please check your internet.');
      } else if (e.type == DioExceptionType.unknown) {
        throw NetworkException('No internet connection');
      } else {
        throw ServerException(e.message ?? 'Server error occurred');
      }
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Chat with AI - flexible method for custom messages and system prompts
  Future<LessonResponse> chat({
    required List<Map<String, String>> messages,
    String? systemPrompt,
    String model = 'gpt-3.5-turbo',
  }) async {
    try {
      final response = await _dioClient.post(
        AppConstants.chatEndpoint,
        data: {
          'messages': messages,
          'model': model,
          if (systemPrompt != null) 'systemPrompt': systemPrompt,
        },
      );

      if (response.statusCode == 200) {
        return LessonResponse.fromJson(response.data);
      } else {
        throw ApiException(
          message: 'Failed to get chat response',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout. Please check your internet.');
      } else if (e.type == DioExceptionType.unknown) {
        throw NetworkException('No internet connection');
      } else {
        throw ServerException(e.message ?? 'Server error occurred');
      }
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Detect language of input text
  Future<LanguageDetectionResponse> detectLanguage(
    LanguageDetectionRequest request,
  ) async {
    try {
      final response = await _dioClient.post(
        AppConstants.detectLanguageEndpoint,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return LanguageDetectionResponse.fromJson(response.data);
      } else {
        throw ApiException(
          message: 'Failed to detect language',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Connection timeout. Please check your internet.');
      } else if (e.type == DioExceptionType.unknown) {
        throw NetworkException('No internet connection');
      } else {
        throw ServerException(e.message ?? 'Server error occurred');
      }
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}

