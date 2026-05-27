import 'dart:async';
import 'dart:convert';

import 'package:am_library/am_library.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_session_state.dart';

/// Persists lightweight UI session per user (local device only).
class SessionPersistenceService {
  SessionPersistenceService._();
  static final SessionPersistenceService instance = SessionPersistenceService._();

  static const String _keyPrefix = 'app_session_v1_';
  static const Duration _debounce = Duration(milliseconds: 400);

  AppSessionState? _cache;
  String? _cacheUserId;
  Timer? _saveTimer;

  String _storageKey(String userId) => '$_keyPrefix$userId';

  Future<AppSessionState?> load(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey(userId));
      if (raw == null || raw.isEmpty) return null;

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final state = AppSessionState.fromJson(json);
      if (state.isExpired) {
        await clear(userId);
        return null;
      }

      _cache = state;
      _cacheUserId = userId;
      AppLogger.info(
        'Session restored: nav=${state.globalNav}, portfolio=${state.portfolioId}, tab=${state.portfolioTabIndex}',
        tag: 'SessionPersistence',
      );
      return state;
    } catch (e) {
      AppLogger.warning(
        'Failed to load session: $e',
        tag: 'SessionPersistence',
      );
      return null;
    }
  }

  AppSessionState? get cached => _cache;

  /// Merges [update] into cached/loaded state and schedules save.
  Future<void> patch(
    String userId,
    AppSessionState Function(AppSessionState current) update,
  ) async {
    if (userId.isEmpty) return;

    final base = (_cacheUserId == userId && _cache != null)
        ? _cache!
        : (await load(userId)) ?? AppSessionState.initial();

    _cache = update(base).copyWith(savedAt: DateTime.now());
    _cacheUserId = userId;
    _scheduleSave(userId);
  }

  Future<void> saveNow(String userId, AppSessionState state) async {
    if (userId.isEmpty) return;
    _cache = state.copyWith(savedAt: DateTime.now());
    _cacheUserId = userId;
    _saveTimer?.cancel();
    await _write(userId, _cache!);
  }

  void _scheduleSave(String userId) {
    _saveTimer?.cancel();
    _saveTimer = Timer(_debounce, () async {
      if (_cacheUserId == userId && _cache != null) {
        await _write(userId, _cache!);
      }
    });
  }

  Future<void> _write(String userId, AppSessionState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey(userId),
        jsonEncode(state.toJson()),
      );
    } catch (e) {
      AppLogger.warning('Failed to save session: $e', tag: 'SessionPersistence');
    }
  }

  Future<void> clear(String userId) async {
    _saveTimer?.cancel();
    _cache = null;
    _cacheUserId = null;
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey(userId));
    } catch (_) {}
  }
}
