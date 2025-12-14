import '../data_sources/remote/ai_api.dart';
import '../data_sources/remote/supabase_api.dart';
import '../data_sources/local/local_storage.dart';
import '../models/lesson_request.dart';
import '../models/lesson_model.dart';
import 'package:uuid/uuid.dart';

class LessonRepository {
  final AIApi _aiApi;
  final SupabaseApi _supabaseApi;
  final AppLocalStorage _localStorage;
  final _uuid = const Uuid();

  LessonRepository(
    this._aiApi,
    this._supabaseApi,
    this._localStorage,
  );

  /// Generate a tiny lesson using AI
  Future<String> generateLesson(LessonRequest request) async {
    final response = await _aiApi.generateLesson(request);
    return response.reply;
  }

  /// Generate a lesson summary from conversation messages
  Future<String> generateLessonFromConversation({
    required List<Map<String, String>> messages,
  }) async {
    final systemPrompt =
        'You are a helpful language tutor. Based on this conversation about language learning and corrections, create a concise learning summary with key vocabulary, useful phrases, and grammar tips. Format your response in three clear sections: 1) Key Vocabulary (5-8 relevant words with translations), 2) Useful Phrases (3-5 practical expressions), and 3) Grammar Tips (1-2 relevant grammar points with simple examples). Keep your response concise and focused on practical language use.';

    final response = await _aiApi.chat(
      messages: messages,
      systemPrompt: systemPrompt,
    );
    return response.reply;
  }

  /// Save lesson to database and local storage
  Future<LessonModel> saveLesson({
    required String userId,
    required String title,
    required String content,
  }) async {
    final lesson = LessonModel(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      content: content,
      createdAt: DateTime.now(),
    );

    // Save to database if user is authenticated
    if (userId.isNotEmpty) {
      try {
        final saved = await _supabaseApi.saveLesson(lesson);
        
        // Also save to local storage
        await _saveLessonLocally(saved);
        
        return saved;
      } catch (e) {
        print('Failed to save to database: $e');
      }
    }

    // Save to local storage
    await _saveLessonLocally(lesson);
    return lesson;
  }

  /// Save lesson to local storage
  Future<void> _saveLessonLocally(LessonModel lesson) async {
    final savedLessons = _localStorage.getSavedLessons();
    savedLessons.insert(0, lesson.toJson());
    await _localStorage.saveLessons(savedLessons);
  }

  /// Get saved lessons
  Future<List<LessonModel>> getSavedLessons(String? userId) async {
    if (userId != null && userId.isNotEmpty) {
      try {
        // Get from database if authenticated
        final lessons = await _supabaseApi.getSavedLessons(userId);
        
        // Update local cache
        await _localStorage.saveLessons(
          lessons.map((l) => l.toJson()).toList(),
        );
        
        return lessons;
      } catch (e) {
        print('Failed to fetch from database: $e');
      }
    }

    // Fall back to local storage
    final localLessons = _localStorage.getSavedLessons();
    return localLessons
        .map((json) => LessonModel.fromJson(json))
        .toList();
  }

  /// Delete lesson
  Future<void> deleteLesson(String lessonId, String? userId) async {
    // Delete from database if authenticated
    if (userId != null && userId.isNotEmpty) {
      try {
        await _supabaseApi.deleteLesson(lessonId, userId);
      } catch (e) {
        print('Failed to delete from database: $e');
      }
    }

    // Delete from local storage
    final localLessons = _localStorage.getSavedLessons();
    localLessons.removeWhere((lesson) => lesson['id'] == lessonId);
    await _localStorage.saveLessons(localLessons);
  }
}

