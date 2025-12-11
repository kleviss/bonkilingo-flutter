import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/api_exception.dart';
import '../../models/user_profile_model.dart';
import '../../models/chat_session_model.dart';
import '../../models/lesson_model.dart';

class SupabaseApi {
  final SupabaseClient _supabase;

  SupabaseApi(this._supabase);

  // ========== Authentication ==========

  Future<User?> signUp(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      throw AppAuthException(e.toString());
    }
  }

  Future<User?> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } catch (e) {
      throw AppAuthException(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AppAuthException(e.toString());
    }
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // ========== User Profile ==========

  Future<UserProfileModel?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfileModel.fromJson(response);
    } catch (e) {
      if (e.toString().contains('406')) {
        return null; // Profile doesn't exist yet
      }
      throw ServerException(e.toString());
    }
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _supabase
          .from('profiles')
          .update({
            ...updates,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ========== Chat Sessions ==========

  Future<ChatSessionModel> saveChatSession(ChatSessionModel session) async {
    try {
      final response = await _supabase
          .from('chat_sessions')
          .insert({
            'user_id': session.userId,
            'corrected_text': session.correctedText,
            'input_text': session.inputText,
            'language': session.language,
            'model': session.model,
          })
          .select()
          .single();

      return ChatSessionModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<ChatSessionModel>> getChatSessions(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('chat_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => ChatSessionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  // ========== Lessons ==========

  Future<LessonModel> saveLesson(LessonModel lesson) async {
    try {
      final response = await _supabase
          .from('saved_lessons')
          .insert({
            'user_id': lesson.userId,
            'title': lesson.title,
            'content': lesson.content,
          })
          .select()
          .single();

      return LessonModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<List<LessonModel>> getSavedLessons(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final response = await _supabase
          .from('saved_lessons')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => LessonModel.fromJson(json))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> deleteLesson(String lessonId, String userId) async {
    try {
      await _supabase
          .from('saved_lessons')
          .delete()
          .eq('id', lessonId)
          .eq('user_id', userId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}

