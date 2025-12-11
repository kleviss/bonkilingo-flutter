import '../data_sources/remote/supabase_api.dart';
import '../data_sources/local/local_storage.dart';
import '../models/user_profile_model.dart';

class UserRepository {
  final SupabaseApi _supabaseApi;
  final AppLocalStorage _localStorage;

  UserRepository(this._supabaseApi, this._localStorage);

  /// Get user profile (from cache first, then network)
  Future<UserProfileModel?> getUserProfile(String userId) async {
    try {
      // Try to get from network first
      final profile = await _supabaseApi.getUserProfile(userId);
      
      if (profile != null) {
        // Cache the profile
        await _localStorage.saveUserData(profile.toJson());
        return profile;
      }
      
      // Fall back to cache if network fails
      final cachedData = _localStorage.getUserData();
      if (cachedData != null) {
        return UserProfileModel.fromJson(cachedData);
      }
      
      return null;
    } catch (e) {
      // If network fails, try cache
      final cachedData = _localStorage.getUserData();
      if (cachedData != null) {
        return UserProfileModel.fromJson(cachedData);
      }
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(
    String userId,
    UserProfileModel profile,
  ) async {
    // Update in database
    await _supabaseApi.updateUserProfile(userId, profile.toJson());
    
    // Update cache
    await _localStorage.saveUserData(profile.toJson());
  }

  /// Update specific fields of user profile
  Future<void> updateUserFields(
    String userId,
    Map<String, dynamic> updates,
  ) async {
    // Update in database
    await _supabaseApi.updateUserProfile(userId, updates);
    
    // Update cache
    final cachedData = _localStorage.getUserData();
    if (cachedData != null) {
      cachedData.addAll(updates);
      await _localStorage.saveUserData(cachedData);
    }
  }
}

