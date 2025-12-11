import 'package:supabase_flutter/supabase_flutter.dart';
import '../data_sources/remote/supabase_api.dart';
import '../data_sources/local/local_storage.dart';

class AuthRepository {
  final SupabaseApi _supabaseApi;
  final AppLocalStorage _localStorage;

  AuthRepository(this._supabaseApi, this._localStorage);

  /// Sign up with email and password
  Future<User?> signUp(String email, String password) async {
    final user = await _supabaseApi.signUp(email, password);
    return user;
  }

  /// Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    final user = await _supabaseApi.signIn(email, password);
    return user;
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabaseApi.signOut();
    await _localStorage.clearAll();
  }

  /// Get current user
  User? getCurrentUser() {
    return _supabaseApi.getCurrentUser();
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _supabaseApi.getCurrentUser() != null;
  }
}

