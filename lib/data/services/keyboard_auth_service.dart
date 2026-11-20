import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/network/dio_client.dart';
import '../data_sources/local/keyboard_settings.dart';

/// Signs the Bonkilingo keyboard in and out along with the app.
///
/// The keyboard can't use the app's Supabase session (refresh tokens are
/// single-use, so two clients refreshing would sign each other out). Instead
/// the app gets a keyboard token from the backend (POST /api/keyboard/token,
/// bonkilingo-backend/keyboard-tokens.js) and stores it in a Keychain group
/// the keyboard can read (ios/BonkilingoKeyboard/KeyboardAuth.swift).
/// Sign-out deletes it and revokes it on the server.
class KeyboardAuthService {
  /// Shared with the keyboard; must match both .entitlements files and
  /// KeyboardAuth.swift. 375CZNUJVV is the Apple team ID (Qendresa Qytetare).
  static const keychainGroup = '375CZNUJVV.com.bonkilingo.shared';
  static const tokenKey = 'keyboard_token';
  static const tokenUserKey = 'keyboard_token_user';

  static const _options = IOSOptions(
    groupId: keychainGroup,
    // The keyboard may need it while the phone is locked after a restart's
    // first unlock (e.g. typing a reply from a notification).
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final DioClient _dioClient;
  final FlutterSecureStorage _storage;
  Future<void>? _running;

  KeyboardAuthService(
    this._dioClient, {
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  /// Makes the keyboard's token match the signed-in user: issues one after
  /// sign-in (or a change of account), removes and revokes it after
  /// sign-out. Calls while one is running wait for it, then run once more.
  Future<void> sync({required String? userId}) async {
    if (!KeyboardSettings.isSupported) return;
    while (_running != null) {
      await _running;
    }
    final run = _sync(userId);
    _running = run;
    try {
      await run;
    } finally {
      _running = null;
    }
  }

  Future<void> _sync(String? userId) async {
    final token = await _storage.read(key: tokenKey, iOptions: _options);
    final owner = await _storage.read(key: tokenUserKey, iOptions: _options);

    if (token != null && userId != null && owner == userId) return;
    if (token != null) await _revoke(token);
    if (userId == null) return;

    final response = await _dioClient.post('/api/keyboard/token');
    final newToken = (response.data as Map?)?['token'];
    if (newToken is! String || !newToken.startsWith('kb_')) {
      throw StateError('No keyboard token in the response');
    }
    await _storage.write(key: tokenKey, value: newToken, iOptions: _options);
    await _storage.write(key: tokenUserKey, value: userId, iOptions: _options);
  }

  /// Removes the token from the Keychain first (so the keyboard stops using
  /// it right away), then revokes it on the server. Revoking is best-effort:
  /// offline, the token stays valid on the server until it is pushed out by
  /// newer ones (5 per account).
  Future<void> _revoke(String token) async {
    await _storage.delete(key: tokenKey, iOptions: _options);
    await _storage.delete(key: tokenUserKey, iOptions: _options);
    try {
      await _dioClient.delete(
        '/api/keyboard/token',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      debugPrint('Revoking the keyboard token failed: $e');
    }
  }
}
