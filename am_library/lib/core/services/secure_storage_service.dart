import 'dart:convert';
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
  static String? _cachedUserDisplayName;

  // Keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userDisplayNameKey = 'user_display_name';
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

  /// Get access token — cache-first; optional expiry validation for authenticated calls.
  Future<String?> getAccessToken({bool checkExpiry = true}) async {
    if (_cachedAccessToken != null && _cachedAccessToken!.isNotEmpty) {
      if (checkExpiry && _isJwtExpired(_cachedAccessToken!)) {
        return null;
      }
      return _cachedAccessToken;
    }
    if (checkExpiry && await isTokenExpired()) {
      return null;
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

  // ── User display name ───────────────────────────────────────────────────

  /// Save user display name — writes to both in-memory cache and secure storage.
  Future<void> saveUserDisplayName(String displayName) async {
    _cachedUserDisplayName = displayName;
    await _storage.write(key: _userDisplayNameKey, value: displayName);
  }

  /// Get user display name — returns from in-memory cache if available.
  Future<String?> getUserDisplayName() async {
    if (_cachedUserDisplayName != null && _cachedUserDisplayName!.isNotEmpty) {
      return _cachedUserDisplayName;
    }
    final name = await _storage.read(key: _userDisplayNameKey);
    if (name == null || name.isEmpty) {
      return null;
    }
    _cachedUserDisplayName = name;
    return name;
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

  /// Helper to check if a JWT token string is expired
  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true; // Invalid token format
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;
      
      final exp = claims['exp'] as int?;
      if (exp == null) return false; // No expiry claim, treat as not expired
      
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isAfter(expiryTime);
    } catch (_) {
      return true; // If parsing fails, treat as expired/invalid
    }
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null || token.isEmpty) return true;
    if (token == 'mock_dev_token') return false;
    
    // Check JWT exp claim first
    if (_isJwtExpired(token)) {
      return true;
    }
    
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
    _cachedUserDisplayName = null;
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
    await _storage.delete(key: _userDisplayNameKey);
    await _storage.delete(key: _tokenExpiryKey);
  }
}
