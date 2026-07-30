// ignore_for_file: non_constant_identifier_names

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserSession {
  static const _storage = FlutterSecureStorage();
  static const _userIdKey = 'session_user_id';
  static const _nameKey = 'session_name';
  static const _emailKey = 'session_email';
  static const _tokenKey = 'session_access_token';

  static int? user_id;
  static String? name;
  static String? email;
  static String? accessToken;

  static bool get isAuthenticated =>
      user_id != null && accessToken != null && accessToken!.isNotEmpty;

  static Future<void> save({
    required int userId,
    required String userName,
    required String userEmail,
    required String token,
  }) async {
    user_id = userId;
    name = userName;
    email = userEmail;
    accessToken = token;

    try {
      await Future.wait([
        _storage.write(key: _userIdKey, value: userId.toString()),
        _storage.write(key: _nameKey, value: userName),
        _storage.write(key: _emailKey, value: userEmail),
        _storage.write(key: _tokenKey, value: token),
      ]);
    } catch (_) {
      // Keep the in-memory session on local non-HTTPS web development.
    }
  }

  static Future<void> restore() async {
    try {
      final values = await Future.wait([
        _storage.read(key: _userIdKey),
        _storage.read(key: _nameKey),
        _storage.read(key: _emailKey),
        _storage.read(key: _tokenKey),
      ]);
      final restoredUserId = int.tryParse(values[0] ?? '');
      final restoredToken = values[3];
      if (restoredUserId == null ||
          restoredToken == null ||
          restoredToken.isEmpty) {
        await clear();
        return;
      }

      user_id = restoredUserId;
      name = values[1];
      email = values[2];
      accessToken = restoredToken;
    } catch (_) {
      // Secure storage can be unavailable on non-HTTPS web origins.
      user_id = null;
      name = null;
      email = null;
      accessToken = null;
    }
  }

  static Future<void> updateProfile({
    required String userName,
    required String userEmail,
  }) async {
    name = userName;
    email = userEmail;
    try {
      await Future.wait([
        _storage.write(key: _nameKey, value: userName),
        _storage.write(key: _emailKey, value: userEmail),
      ]);
    } catch (_) {
      // The in-memory profile remains updated.
    }
  }

  static Future<void> clear() async {
    user_id = null;
    name = null;
    email = null;
    accessToken = null;
    try {
      await Future.wait([
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _nameKey),
        _storage.delete(key: _emailKey),
        _storage.delete(key: _tokenKey),
      ]);
    } catch (_) {
      // Memory is already cleared, so logout still succeeds locally.
    }
  }
}
