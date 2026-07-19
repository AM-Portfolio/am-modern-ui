import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stable anon + session ids for product telemetry (not auth session).
class TelemetryIds {
  TelemetryIds._();
  static final TelemetryIds instance = TelemetryIds._();

  static const _anonKey = 'am_telemetry_anon_id';
  static const _sessionKey = 'am_telemetry_session_id';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String? _anonId;
  String? _sessionId;

  Future<void> ensureReady() async {
    _anonId ??= await _storage.read(key: _anonKey);
    if (_anonId == null || _anonId!.isEmpty) {
      _anonId = _newUuid();
      await _storage.write(key: _anonKey, value: _anonId);
    }
    _sessionId ??= await _storage.read(key: _sessionKey);
    if (_sessionId == null || _sessionId!.isEmpty) {
      await rotateSession();
    }
  }

  Future<void> rotateSession() async {
    _sessionId = _newUuid();
    await _storage.write(key: _sessionKey, value: _sessionId);
  }

  String get anonId => _anonId ?? 'pending';
  String get sessionId => _sessionId ?? 'pending';

  static String _newUuid() {
    final r = Random.secure();
    final bytes = List<int>.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int b) => b.toRadixString(16).padLeft(2, '0');
    final h = bytes.map(hex).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-'
        '${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  static String platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return defaultTargetPlatform.name;
    }
  }
}
