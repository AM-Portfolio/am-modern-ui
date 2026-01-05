import 'package:hive_flutter/hive_flutter.dart';

/// Core cache service for storing data in browser local storage
/// Uses Hive for efficient key-value storage with TTL support
class CacheService {
  static const String _boxName = 'am_cache';
  static Box? _box;

  /// Initialize Hive and open the cache box
  /// Call this during app startup
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  /// Get cached value for the given key
  /// Returns null if not found or expired
  Future<T?> get<T>(String key) async {
    if (_box == null) throw StateError('CacheService not initialized');

    final cached = _box!.get(key);
    if (cached == null) return null;

    // Check TTL
    final timestamp = _box!.get('${key}_timestamp') as int?;
    final ttl = _box!.get('${key}_ttl') as int?;

    if (timestamp != null && ttl != null) {
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (age > ttl) {
        await clear(key);
        return null;
      }
    }

    return cached as T;
  }

  /// Store value in cache with optional TTL
  /// TTL (Time-To-Live) determines how long the cache is valid
  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    if (_box == null) throw StateError('CacheService not initialized');

    await _box!.put(key, value);

    if (ttl != null) {
      await _box!.put('${key}_timestamp', DateTime.now().millisecondsSinceEpoch);
      await _box!.put('${key}_ttl', ttl.inMilliseconds);
    }
  }

  /// Check if key exists and is not expired
  Future<bool> has(String key) async {
    final value = await get(key);
    return value != null;
  }

  /// Clear specific cache entry
  Future<void> clear(String key) async {
    if (_box == null) throw StateError('CacheService not initialized');

    await _box!.delete(key);
    await _box!.delete('${key}_timestamp');
    await _box!.delete('${key}_ttl');
  }

  /// Clear all cached data
  Future<void> clearAll() async {
    if (_box == null) throw StateError('CacheService not initialized');
    await _box!.clear();
  }

  /// Get all keys in cache
  Iterable<String> get keys {
    if (_box == null) throw StateError('CacheService not initialized');
    return _box!.keys.cast<String>().where((key) => !key.endsWith('_timestamp') && !key.endsWith('_ttl'));
  }

  /// Close the cache box
  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}
