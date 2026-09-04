import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';

import 'offline_sync_config.dart';
import 'outbox_item.dart';

class OutboxQueue {
  OutboxQueue({required OfflineSyncConfig config}) : _config = config;

  static const _boxName = 'offline_sync_v1_outbox';
  static const maxAttempts = 5;

  final OfflineSyncConfig _config;
  Box<String>? _box;
  final _pendingController = BehaviorSubject<int>.seeded(0);

  Stream<int> get pendingCountStream => _pendingController.stream;
  int get pendingCount => _pendingController.value;

  Future<void> ensureInitialized() async {
    if (_box != null) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
    _emitPending();
  }

  String _key(String userId, String clientMutationId) =>
      '${_config.appId}/$userId/$clientMutationId';

  Future<void> enqueue({
    required String userId,
    required OutboxItem item,
  }) async {
    await ensureInitialized();
    await _box!.put(_key(userId, item.clientMutationId), jsonEncode(item.toJson()));
    _emitPending();
  }

  Future<List<OutboxItem>> listForUser(String userId) async {
    await ensureInitialized();
    final prefix = '${_config.appId}/$userId/';
    final items = <OutboxItem>[];
    for (final key in _box!.keys) {
      if (key is! String || !key.startsWith(prefix)) continue;
      final raw = _box!.get(key);
      if (raw == null) continue;
      items.add(OutboxItem.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    }
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
  }

  Future<List<OutboxItem>> pendingFlushable(String userId) async {
    final all = await listForUser(userId);
    return all
        .where(
          (i) =>
              i.status == OutboxItemStatus.queued ||
              i.status == OutboxItemStatus.flushing ||
              i.status == OutboxItemStatus.failed,
        )
        .where((i) => i.attempts < maxAttempts)
        .toList(growable: false);
  }

  Future<void> update({
    required String userId,
    required OutboxItem item,
  }) async {
    await ensureInitialized();
    if (item.status == OutboxItemStatus.done) {
      await _box!.delete(_key(userId, item.clientMutationId));
    } else {
      await _box!.put(
        _key(userId, item.clientMutationId),
        jsonEncode(item.toJson()),
      );
    }
    _emitPending();
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
    _emitPending();
  }

  void _emitPending() {
    if (_box == null) {
      _pendingController.add(0);
      return;
    }
    var count = 0;
    for (final raw in _box!.values) {
      try {
        final item =
            OutboxItem.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        if (item.status != OutboxItemStatus.done) count++;
      } catch (_) {}
    }
    _pendingController.add(count);
  }

  Future<void> dispose() async {
    await _pendingController.close();
  }
}
