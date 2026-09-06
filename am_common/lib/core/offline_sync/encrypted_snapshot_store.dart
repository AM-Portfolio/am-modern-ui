import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'offline_sync_config.dart';

class EncryptedSnapshotStore {
  EncryptedSnapshotStore({
    required OfflineSyncConfig config,
    FlutterSecureStorage? secureStorage,
  })  : _config = config,
        _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _boxName = 'offline_sync_v1_snapshots';
  static const _dekKeyPrefix = 'offline_sync_v1_dek_';

  final OfflineSyncConfig _config;
  final FlutterSecureStorage _secureStorage;
  Box<String>? _box;
  enc.Key? _key;

  Future<void> ensureInitialized() async {
    if (_box != null && _key != null) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
    _key = await _loadOrCreateDek();
  }

  Future<enc.Key> _loadOrCreateDek() async {
    final storageKey = '$_dekKeyPrefix${_config.appId}';
    final existing = await _secureStorage.read(key: storageKey);
    if (existing != null && existing.isNotEmpty) {
      return enc.Key.fromBase64(existing);
    }
    final key = enc.Key.fromSecureRandom(32);
    await _secureStorage.write(key: storageKey, value: key.base64);
    return key;
  }

  String _scopedKey(String userId, String domainId, String recordKey) =>
      '${_config.appId}/$userId/$domainId/$recordKey';

  Future<void> putJson({
    required String userId,
    required String domainId,
    required String recordKey,
    required Map<String, dynamic> json,
    required DateTime fetchedAt,
  }) async {
    await ensureInitialized();
    final envelope = <String, dynamic>{
      'fetchedAt': fetchedAt.toIso8601String(),
      'payload': json,
    };
    final cipher = _encrypt(jsonEncode(envelope));
    await _box!.put(_scopedKey(userId, domainId, recordKey), cipher);
  }

  Future<({Map<String, dynamic> payload, DateTime fetchedAt})?> getJson({
    required String userId,
    required String domainId,
    required String recordKey,
  }) async {
    await ensureInitialized();
    final cipher = _box!.get(_scopedKey(userId, domainId, recordKey));
    if (cipher == null) return null;
    try {
      final decoded =
          jsonDecode(_decrypt(cipher)) as Map<String, dynamic>;
      return (
        payload: decoded['payload'] as Map<String, dynamic>,
        fetchedAt: DateTime.parse(decoded['fetchedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  Future<int> approximateUserBytes(String userId) async {
    await ensureInitialized();
    final prefix = '${_config.appId}/$userId/';
    var total = 0;
    for (final key in _box!.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;
      final value = _box!.get(key);
      if (value != null) total += value.length;
    }
    return total;
  }

  Future<void> clearUser(String userId) async {
    await ensureInitialized();
    final prefix = '${_config.appId}/$userId/';
    final toDelete = _box!.keys
        .whereType<String>()
        .where((k) => k.startsWith(prefix))
        .toList(growable: false);
    for (final key in toDelete) {
      await _box!.delete(key);
    }
  }

  String _encrypt(String plain) {
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc));
    final encrypted = encrypter.encrypt(plain, iv: iv);
    final combined = Uint8List.fromList([...iv.bytes, ...encrypted.bytes]);
    return base64Encode(combined);
  }

  String _decrypt(String cipherText) {
    final combined = base64Decode(cipherText);
    final iv = enc.IV(Uint8List.fromList(combined.sublist(0, 16)));
    final data = enc.Encrypted(Uint8List.fromList(combined.sublist(16)));
    final encrypter = enc.Encrypter(enc.AES(_key!, mode: enc.AESMode.cbc));
    return encrypter.decrypt(data, iv: iv);
  }
}
