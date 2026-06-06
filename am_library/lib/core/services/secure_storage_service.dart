import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing sensitive data like tokens
class SecureStorageService {
  SecureStorageService()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
  final FlutterSecureStorage _storage;

  // Keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _tokenExpiryKey = 'token_expiry';

  static String get _fallbackToken {
    const token = String.fromEnvironment('AM_DEV_TOKEN');
    if (token.isNotEmpty && token != 'mock_dev_token') return token;
    return '';
  }

  static String get _fallbackUserId {
    const userId = String.fromEnvironment('AM_DEV_USER_ID');
    if (userId.isNotEmpty && userId != 'local-dev-user') return userId;
    return '';
  }

  static String get _fallbackUserEmail {
    const email = String.fromEnvironment('AM_DEV_USER_EMAIL');
    if (email.isNotEmpty) return email;
    return '';
  }

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null || token.isEmpty || token == 'mock_dev_token') {
      final fallback = _fallbackToken;
      return fallback.isEmpty ? null : fallback;
    }
    return token;
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async =>
      _storage.read(key: _refreshTokenKey);

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    final userId = await _storage.read(key: _userIdKey);
    if (userId == null || userId.isEmpty || userId == 'local-dev-user') {
      final fallback = _fallbackUserId;
      return fallback.isEmpty ? null : fallback;
    }
    return userId;
  }

  /// Save user email
  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _userEmailKey, value: email);
  }

  /// Get user email
  Future<String?> getUserEmail() async {
    final email = await _storage.read(key: _userEmailKey);
    if (email == null || email.isEmpty) {
      final fallback = _fallbackUserEmail;
      return fallback.isEmpty ? null : fallback;
    }
    return email;
  }

  /// Save token expiry timestamp
  Future<void> saveTokenExpiry(DateTime expiry) async {
    await _storage.write(key: _tokenExpiryKey, value: expiry.toIso8601String());
  }

  /// Get token expiry timestamp
  Future<DateTime?> getTokenExpiry() async {
    final expiryStr = await _storage.read(key: _tokenExpiryKey);
    if (expiryStr != null) {
      return DateTime.parse(expiryStr);
    }
    return DateTime.now().add(const Duration(days: 365));
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().isAfter(expiry);
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Clear only authentication data
  Future<void> clearAuthData() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _tokenExpiryKey);
  }
}
