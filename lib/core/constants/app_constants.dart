class AppConstants {
  // App Info
  static const String appName = 'Bonkilingo';
  static const String appVersion = '1.0.0';

  // API Endpoints (Points to standalone backend)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3001',  // Standalone backend
  );
  
  static const String correctEndpoint = '/api/correct';
  static const String chatEndpoint = '/api/chat';
  static const String detectLanguageEndpoint = '/api/detect-language';

  // Supabase
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Storage Keys
  static const String userDataKey = 'user_data';
  static const String chatHistoryKey = 'chat_history';
  static const String savedLessonsKey = 'saved_lessons';
  static const String authTokenKey = 'auth_token';

  // Hive Boxes
  static const String userBox = 'user_box';
  static const String chatBox = 'chat_box';
  static const String lessonBox = 'lesson_box';

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration debounceDelay = Duration(milliseconds: 600);

  // Language Detection
  static const int minLanguageDetectionLength = 15;
  static const int minLanguageDetectionWords = 3;

  // Points System
  static const int minCorrectionPoints = 5;
  static const int mediumCorrectionPoints = 10;
  static const int largeCorrectionPoints = 15;
  static const int smallTextWordCount = 10;
  static const int mediumTextWordCount = 50;
  static const int lessonSavePoints = 5;
  static const int streakBonusPerWeek = 50;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxHistoryItems = 100;

  AppConstants._();
}

