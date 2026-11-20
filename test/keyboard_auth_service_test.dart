import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bonkilingo/core/network/dio_client.dart';
import 'package:bonkilingo/data/services/keyboard_auth_service.dart';

/// Records requests instead of sending them.
class _FakeDioClient extends DioClient {
  final calls = <String>[];
  int issued = 0;

  @override
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls.add('POST $path');
    issued++;
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 201,
      data: {'token': 'kb_token$issued'},
    );
  }

  @override
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    calls.add('DELETE $path ${options?.headers?['Authorization']}');
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 204,
    );
  }
}

/// An in-memory Keychain that also checks the shared group is used.
class _FakeStorage extends FlutterSecureStorage {
  _FakeStorage();

  final Map<String, String> values = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    expect(iOptions?.params['groupId'], KeyboardAuthService.keychainGroup);
    return values[key];
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    expect(iOptions?.params['groupId'], KeyboardAuthService.keychainGroup);
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    expect(iOptions?.params['groupId'], KeyboardAuthService.keychainGroup);
    values.remove(key);
  }
}

void main() {
  late _FakeDioClient dio;
  late _FakeStorage storage;
  late KeyboardAuthService service;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    dio = _FakeDioClient();
    storage = _FakeStorage();
    service = KeyboardAuthService(dio, storage: storage);
  });

  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('issues and stores a token after sign-in', () async {
    await service.sync(userId: 'user-1');
    expect(dio.calls, ['POST /api/keyboard/token']);
    expect(storage.values[KeyboardAuthService.tokenKey], 'kb_token1');
    expect(storage.values[KeyboardAuthService.tokenUserKey], 'user-1');
  });

  test('keeps the token while the same user stays signed in', () async {
    await service.sync(userId: 'user-1');
    await service.sync(userId: 'user-1');
    expect(dio.calls, ['POST /api/keyboard/token']);
  });

  test('removes and revokes the token on sign-out', () async {
    await service.sync(userId: 'user-1');
    await service.sync(userId: null);
    expect(dio.calls.last, 'DELETE /api/keyboard/token Bearer kb_token1');
    expect(storage.values, isEmpty);
  });

  test('replaces the token when another account signs in', () async {
    await service.sync(userId: 'user-1');
    await service.sync(userId: 'user-2');
    expect(dio.calls, [
      'POST /api/keyboard/token',
      'DELETE /api/keyboard/token Bearer kb_token1',
      'POST /api/keyboard/token',
    ]);
    expect(storage.values[KeyboardAuthService.tokenKey], 'kb_token2');
    expect(storage.values[KeyboardAuthService.tokenUserKey], 'user-2');
  });

  test('does nothing when signed out with no token', () async {
    await service.sync(userId: null);
    expect(dio.calls, isEmpty);
  });
}
