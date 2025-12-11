import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/network/dio_client.dart';
import '../../data/data_sources/local/local_storage.dart';
import '../../data/data_sources/remote/ai_api.dart';
import '../../data/data_sources/remote/supabase_api.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/correction_repository.dart';
import '../../data/repositories/language_repository.dart';
import '../../data/repositories/lesson_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/points_service.dart';

// ========== Core Providers ==========

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final localStorageProvider = Provider<AppLocalStorage>((ref) {
  return AppLocalStorage();
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ========== API Providers ==========

final aiApiProvider = Provider<AIApi>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AIApi(dioClient);
});

final supabaseApiProvider = Provider<SupabaseApi>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SupabaseApi(supabase);
});

// ========== Repository Providers ==========

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabaseApi = ref.watch(supabaseApiProvider);
  final localStorage = ref.watch(localStorageProvider);
  return AuthRepository(supabaseApi, localStorage);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final supabaseApi = ref.watch(supabaseApiProvider);
  final localStorage = ref.watch(localStorageProvider);
  return UserRepository(supabaseApi, localStorage);
});

final correctionRepositoryProvider = Provider<CorrectionRepository>((ref) {
  final aiApi = ref.watch(aiApiProvider);
  final supabaseApi = ref.watch(supabaseApiProvider);
  final localStorage = ref.watch(localStorageProvider);
  return CorrectionRepository(aiApi, supabaseApi, localStorage);
});

final lessonRepositoryProvider = Provider<LessonRepository>((ref) {
  final aiApi = ref.watch(aiApiProvider);
  final supabaseApi = ref.watch(supabaseApiProvider);
  final localStorage = ref.watch(localStorageProvider);
  return LessonRepository(aiApi, supabaseApi, localStorage);
});

final languageRepositoryProvider = Provider<LanguageRepository>((ref) {
  final aiApi = ref.watch(aiApiProvider);
  return LanguageRepository(aiApi);
});

// ========== Service Providers ==========

final pointsServiceProvider = Provider<PointsService>((ref) {
  return PointsService();
});

