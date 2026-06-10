import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing sensitive data like tokens.
///
/// **In-memory cache layer**: After the first read (or after [saveAccessToken]
/// is called at login), values are served from memory. This means every service
/// that calls [getAccessToken] or [getUserId] is automatically cache-hot — no
/// changes needed in any service file.
class SecureStorageService {
  SecureStorageService()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
  final FlutterSecureStorage _storage;

  // ── In-memory cache ──────────────────────────────────────────────────────
  // Static so all instances share the same cache (singleton-like behaviour).
  static String? _cachedAccessToken;
  static String? _cachedUserId;
  static String? _cachedUserEmail;

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

  // ── Token ────────────────────────────────────────────────────────────────

  /// Save access token — writes to both in-memory cache and secure storage.
  Future<void> saveAccessToken(String token) async {
    _cachedAccessToken = token;
    await _storage.write(key: _accessTokenKey, value: token);
  }

  /// Get access token — returns from in-memory cache if available,
  /// otherwise reads from secure storage and populates the cache.
  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null && _cachedAccessToken!.isNotEmpty) {
      return _cachedAccessToken;
    }
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null || token.isEmpty || token == 'mock_dev_token') {
      final fallback = _fallbackToken;
      if (fallback.isNotEmpty) {
        _cachedAccessToken = fallback;
        return fallback;
      }
      return null;
    }
    _cachedAccessToken = token;
    return token;
  }

  // ── Refresh token ────────────────────────────────────────────────────────

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async =>
      _storage.read(key: _refreshTokenKey);

  // ── User ID ──────────────────────────────────────────────────────────────

  /// Save user ID — writes to both in-memory cache and secure storage.
  Future<void> saveUserId(String userId) async {
    _cachedUserId = userId;
    await _storage.write(key: _userIdKey, value: userId);
  }

  /// Get user ID — returns from in-memory cache if available.
  Future<String?> getUserId() async {
    if (_cachedUserId != null && _cachedUserId!.isNotEmpty) {
      return _cachedUserId;
    }
    final userId = await _storage.read(key: _userIdKey);
    if (userId == null || userId.isEmpty || userId == 'local-dev-user') {
      final fallback = _fallbackUserId;
      if (fallback.isNotEmpty) {
        _cachedUserId = fallback;
        return fallback;
      }
      return null;
    }
    _cachedUserId = userId;
    return userId;
  }

  // ── User email ───────────────────────────────────────────────────────────

  /// Save user email — writes to both in-memory cache and secure storage.
  Future<void> saveUserEmail(String email) async {
    _cachedUserEmail = email;
    await _storage.write(key: _userEmailKey, value: email);
  }

  /// Get user email — returns from in-memory cache if available.
  Future<String?> getUserEmail() async {
    if (_cachedUserEmail != null && _cachedUserEmail!.isNotEmpty) {
      return _cachedUserEmail;
    }
    final email = await _storage.read(key: _userEmailKey);
    if (email == null || email.isEmpty) {
      final fallback = _fallbackUserEmail;
      if (fallback.isNotEmpty) {
        _cachedUserEmail = fallback;
        return fallback;
      }
      return null;
    }
    _cachedUserEmail = email;
    return email;
  }

  // ── Expiry ───────────────────────────────────────────────────────────────

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

  // ── Cache management ─────────────────────────────────────────────────────

  /// Evict the in-memory cache without touching secure storage.
  /// Call when you want the next read to re-hydrate from storage.
  static void evictCache() {
    _cachedAccessToken = null;
    _cachedUserId = null;
    _cachedUserEmail = null;
  }

  // ── Clearing ─────────────────────────────────────────────────────────────

  /// Clear all stored data (persistent + in-memory cache).
  Future<void> clearAll() async {
    evictCache();
    await _storage.deleteAll();
  }

  /// Clear only authentication data (persistent + in-memory cache).
  Future<void> clearAuthData() async {
    evictCache();
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _tokenExpiryKey);
  }
}
