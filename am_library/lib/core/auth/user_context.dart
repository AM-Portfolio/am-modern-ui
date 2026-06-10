import 'dart:convert';

import '../services/secure_storage_service.dart';
import '../utils/logger.dart';

/// Centralized, lazily-loaded context for the authenticated user.
///
/// **Usage** (from any UI module):
/// ```dart
/// // Get the Bearer header — throws if not authenticated.
/// final auth = await UserContext.instance.bearerToken;
///
/// // Get the raw access token (no prefix).
/// final token = await UserContext.instance.accessToken;
///
/// // Get the user ID stored at login.
/// final uid  = await UserContext.instance.userId;
///
/// // Invalidate the in-memory cache (call at logout).
/// UserContext.instance.invalidate();
/// ```
///
/// All results are **in-memory cached** after the first read so subsequent
/// calls within the same request lifecycle are synchronous-fast.
class UserContext {
  UserContext._({required SecureStorageService storage})
      : _storage = storage;

  // ── Singleton ──────────────────────────────────────────────────────────────

  static UserContext? _instance;

  /// Returns the singleton, lazily creating it against [SecureStorageService].
  /// Override [storage] only in tests.
  static UserContext get instance {
    _instance ??= UserContext._(storage: SecureStorageService());
    return _instance!;
  }

  /// Replace the singleton — useful for testing with mock storage.
  // ignore: use_setters_to_change_properties
  static void overrideForTesting(UserContext ctx) => _instance = ctx;

  // ── Internal state ─────────────────────────────────────────────────────────

  final SecureStorageService _storage;

  String? _cachedToken;
  String? _cachedUserId;
  String? _cachedEmail;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// The raw JWT access token (no `Bearer ` prefix).
  /// Throws [UnauthenticatedException] if no token is available.
  Future<String> get accessToken async {
    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      return _cachedToken!;
    }
    final token = await _storage.getAccessToken();
    if (token == null || token.isEmpty) {
      AppLogger.warning('UserContext: access token missing', tag: 'UserContext');
      throw const UnauthenticatedException();
    }
    _cachedToken = token;
    return token;
  }

  /// The `Authorization` header value — `Bearer <token>`.
  /// Throws [UnauthenticatedException] if no token is available.
  Future<String> get bearerToken async => 'Bearer ${await accessToken}';

  /// The authenticated user ID (stored at login).
  /// Returns `null` if not yet populated (e.g. anonymous / demo).
  Future<String?> get userId async {
    if (_cachedUserId != null) return _cachedUserId;
    _cachedUserId = await _storage.getUserId();
    return _cachedUserId;
  }

  /// The authenticated user's email address.
  /// Returns `null` if not yet populated.
  Future<String?> get email async {
    if (_cachedEmail != null) return _cachedEmail;
    _cachedEmail = await _storage.getUserEmail();
    return _cachedEmail;
  }

  /// Whether a valid (non-expired) session exists.
  Future<bool> get isAuthenticated async {
    try {
      final token = await _storage.getAccessToken();
      if (token == null || token.isEmpty) return false;
      final expired = await _storage.isTokenExpired();
      return !expired;
    } catch (_) {
      return false;
    }
  }

  /// Decode and return the full JWT payload as a map — zero extra deps.
  Future<Map<String, dynamic>?> get jwtPayload async {
    try {
      final token = await accessToken;
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      return json.decode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ── Cache management ───────────────────────────────────────────────────────

  /// Populate the in-memory cache proactively (call after successful login
  /// so the first API call is cache-hot).
  void populate({
    required String accessToken,
    required String userId,
    required String email,
  }) {
    _cachedToken = accessToken;
    _cachedUserId = userId;
    _cachedEmail = email;
    AppLogger.info(
      'UserContext: session populated for user $userId',
      tag: 'UserContext',
    );
  }

  /// Evict the in-memory cache.  Call this at logout or token refresh so the
  /// next read goes back to [SecureStorageService].
  /// Also evicts the [SecureStorageService] static cache so all callers
  /// that use `_storage.getAccessToken()` re-hydrate from secure storage.
  void invalidate() {
    _cachedToken = null;
    _cachedUserId = null;
    _cachedEmail = null;
    SecureStorageService.evictCache(); // keep storage-level cache in sync
    AppLogger.info('UserContext: cache invalidated', tag: 'UserContext');
  }
}

// ── Exceptions ─────────────────────────────────────────────────────────────

/// Thrown when a [UserContext] operation requires an authenticated session
/// but no valid token is present in storage.
class UnauthenticatedException implements Exception {
  const UnauthenticatedException(
      [this.message = 'Authentication required. Please log in.']);
  final String message;

  @override
  String toString() => 'UnauthenticatedException: $message';
}
