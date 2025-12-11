import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_exception.dart';

class AppLocalStorage {
  Box? _userBox;
  Box? _chatBox;
  Box? _lessonBox;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    try {
      await Hive.initFlutter();
      
      _userBox = await Hive.openBox(AppConstants.userBox);
      _chatBox = await Hive.openBox(AppConstants.chatBox);
      _lessonBox = await Hive.openBox(AppConstants.lessonBox);
    } catch (e) {
      throw CacheException('Failed to initialize local storage: $e');
    }
  }

  // ========== User Data ==========

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      await _userBox?.put(AppConstants.userDataKey, userData);
    } catch (e) {
      throw CacheException('Failed to save user data: $e');
    }
  }

  Map<String, dynamic>? getUserData() {
    try {
      final data = _userBox?.get(AppConstants.userDataKey);
      return data != null ? Map<String, dynamic>.from(data) : null;
    } catch (e) {
      throw CacheException('Failed to get user data: $e');
    }
  }

  Future<void> clearUserData() async {
    try {
      await _userBox?.delete(AppConstants.userDataKey);
    } catch (e) {
      throw CacheException('Failed to clear user data: $e');
    }
  }

  // ========== Chat History ==========

  Future<void> saveChatHistory(List<Map<String, dynamic>> chatHistory) async {
    try {
      await _chatBox?.put(AppConstants.chatHistoryKey, chatHistory);
    } catch (e) {
      throw CacheException('Failed to save chat history: $e');
    }
  }

  List<Map<String, dynamic>> getChatHistory() {
    try {
      final data = _chatBox?.get(AppConstants.chatHistoryKey);
      if (data == null) return [];
      
      return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw CacheException('Failed to get chat history: $e');
    }
  }

  Future<void> clearChatHistory() async {
    try {
      await _chatBox?.delete(AppConstants.chatHistoryKey);
    } catch (e) {
      throw CacheException('Failed to clear chat history: $e');
    }
  }

  // ========== Saved Lessons ==========

  Future<void> saveLessons(List<Map<String, dynamic>> lessons) async {
    try {
      await _lessonBox?.put(AppConstants.savedLessonsKey, lessons);
    } catch (e) {
      throw CacheException('Failed to save lessons: $e');
    }
  }

  List<Map<String, dynamic>> getSavedLessons() {
    try {
      final data = _lessonBox?.get(AppConstants.savedLessonsKey);
      if (data == null) return [];
      
      return (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      throw CacheException('Failed to get saved lessons: $e');
    }
  }

  Future<void> clearSavedLessons() async {
    try {
      await _lessonBox?.delete(AppConstants.savedLessonsKey);
    } catch (e) {
      throw CacheException('Failed to clear saved lessons: $e');
    }
  }

  // ========== General ==========

  Future<void> clearAll() async {
    try {
      await _userBox?.clear();
      await _chatBox?.clear();
      await _lessonBox?.clear();
    } catch (e) {
      throw CacheException('Failed to clear all data: $e');
    }
  }
}

