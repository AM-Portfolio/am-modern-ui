import 'dart:async';
import 'dart:convert';

import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import 'encrypted_snapshot_store.dart';
import 'mutation_adapter.dart';
import 'offline_sync_config.dart';
import 'offline_sync_telemetry.dart';
import 'offline_widget_policy.dart';
import 'outbox_item.dart';
import 'outbox_queue.dart';
import 'reachability_service.dart';
import 'snapshot_adapter.dart';

typedef FlushPausedProvider = bool Function();
typedef CanFlushAsync = Future<bool> Function();
typedef FlagEnabled = bool Function();

class OfflineSyncEngine {
  OfflineSyncEngine({
    required this.config,
    ReachabilityService? reachability,
    EncryptedSnapshotStore? store,
    OutboxQueue? outbox,
    OfflineSyncTelemetry? telemetry,
    FlushPausedProvider? isFlushPaused,
    CanFlushAsync? canFlush,
    FlagEnabled? isReadsEnabled,
    FlagEnabled? isWritesEnabled,
  })  : reachability = reachability ?? ReachabilityService(),
        store = store ?? EncryptedSnapshotStore(config: config),
        outbox = outbox ?? OutboxQueue(config: config),
        telemetry = telemetry ?? OfflineSyncTelemetry(config),
        _isFlushPaused = isFlushPaused ?? (() => false),
        _canFlush = canFlush ?? (() async => true),
        _isReadsEnabled = isReadsEnabled ?? (() => false),
        _isWritesEnabled = isWritesEnabled ?? (() => false);

  final OfflineSyncConfig config;
  final ReachabilityService reachability;
  final EncryptedSnapshotStore store;
  final OutboxQueue outbox;
  final OfflineSyncTelemetry telemetry;
  final FlushPausedProvider _isFlushPaused;
  final CanFlushAsync _canFlush;
  final FlagEnabled _isReadsEnabled;
  final FlagEnabled _isWritesEnabled;
  final _uuid = const Uuid();

  final Map<String, SnapshotAdapter<dynamic>> _snapshots = {};
  final Map<String, MutationAdapter> _mutations = {};
  final _conflictController = BehaviorSubject<String?>.seeded(null);
  final _overlayShownUsers = <String>{};

  StreamSubscription<bool>? _onlineSub;
  bool _started = false;
  bool _flushing = false;

  Stream<bool> get isOnlineStream => reachability.isOnlineStream;
  bool get isOnline => reachability.isOnline;
  Stream<int> get pendingCountStream => outbox.pendingCountStream;
  int get pendingCount => outbox.pendingCount;
  Stream<String?> get conflictMessageStream => _conflictController.stream;

  bool get readsEnabled => _isReadsEnabled();
  bool get writesEnabled => readsEnabled && _isWritesEnabled();

  bool shouldServeCache(OfflineWidgetId id) {
    if (!readsEnabled) return false;
    final policy = config.policyFor(id);
    if (policy == null) return false;
    if (!config.isDomainEnabled(policy.domain)) return false;
    return policy.cacheOnFailure;
  }

  bool shouldHideWhenOffline(OfflineWidgetId id) {
    if (!readsEnabled) return false;
    if (isOnline) return false;
    final policy = config.policyFor(id);
    if (policy == null) return false;
    if (!config.isDomainEnabled(policy.domain)) return false;
    if (config.ui.hideLiveMovers && id == OfflineWidgetId.dashboardTopMovers) {
      return true;
    }
    return policy.hideWhenOffline;
  }

  bool allowQueuedWrites(OfflineWidgetId id) {
    if (!writesEnabled) return false;
    final policy = config.policyFor(id);
    if (policy == null) return false;
    if (!config.isDomainEnabled(policy.domain)) return false;
    return policy.allowQueuedWrites;
  }

  bool shouldShowOverlayOnce(String userId) {
    if (!config.ui.overlayOnce) return false;
    if (_overlayShownUsers.contains(userId)) return false;
    _overlayShownUsers.add(userId);
    telemetry.shellShown();
    return true;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await store.ensureInitialized();
    await outbox.ensureInitialized();
    await reachability.start();
    _onlineSub = reachability.isOnlineStream.listen((online) {
      if (online) {
        unawaited(flushWhenOnline());
      }
    });
    await flushWhenOnline();
  }

  void registerSnapshotAdapter(SnapshotAdapter<dynamic> adapter) {
    _snapshots[adapter.domainId] = adapter;
  }

  void registerMutationAdapter(MutationAdapter adapter) {
    _mutations[adapter.type] = adapter;
  }

  SnapshotAdapter<dynamic>? snapshotAdapter(String domainId) =>
      _snapshots[domainId];

  String? get currentUserId => config.userIdProvider();

  void reportNetworkFailure() => reachability.reportNetworkFailure();

  void reportNetworkSuccess() => reachability.reportNetworkSuccess();

  Future<String> enqueueMutation({
    required String type,
    required Map<String, dynamic> payload,
    String? localFilePath,
    String? clientMutationId,
    OfflineWidgetId? widgetId,
  }) async {
    if (widgetId != null && !allowQueuedWrites(widgetId)) {
      throw StateError('Offline writes disabled for $widgetId');
    }
    if (!writesEnabled) {
      throw StateError('Offline writes flag is off');
    }
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) {
      throw StateError('OfflineSyncEngine: no userId for enqueue');
    }
    final id = clientMutationId ?? _uuid.v4();
    final item = OutboxItem(
      clientMutationId: id,
      type: type,
      payloadJson: jsonEncode(payload),
      createdAt: DateTime.now().toUtc(),
      status: OutboxItemStatus.queued,
      localFilePath: localFilePath,
    );
    final adapter = _mutations[type];
    if (adapter != null) {
      await adapter.applyOptimistic(item);
    }
    await outbox.enqueue(userId: userId, item: item);
    telemetry.outboxEnqueued(type);
    if (isOnline && !_isFlushPaused()) {
      unawaited(flushWhenOnline());
    }
    return id;
  }

  Future<void> flushWhenOnline() async {
    if (!isOnline || _isFlushPaused() || _flushing) return;
    if (!await _canFlush()) return;
    final userId = currentUserId;
    if (userId == null || userId.isEmpty) return;

    _flushing = true;
    try {
      final pending = await outbox.pendingFlushable(userId);
      final ordered = _orderForFlush(pending);
      for (final item in ordered) {
        if (!isOnline || _isFlushPaused()) break;
        await _flushOne(userId, item);
      }
    } finally {
      _flushing = false;
    }
  }

  List<OutboxItem> _orderForFlush(List<OutboxItem> items) {
    const priority = <String, int>{
      'uploadPortfolioDocument': 0,
      'createTrade': 1,
      'updateTrade': 1,
      'aiChatSend': 2,
    };
    final copy = [...items];
    copy.sort((a, b) {
      final pa = priority[a.type] ?? 50;
      final pb = priority[b.type] ?? 50;
      if (pa != pb) return pa.compareTo(pb);
      return a.createdAt.compareTo(b.createdAt);
    });
    return copy;
  }

  Future<void> _flushOne(String userId, OutboxItem item) async {
    final adapter = _mutations[item.type];
    if (adapter == null) {
      await outbox.update(
        userId: userId,
        item: item.copyWith(
          status: OutboxItemStatus.needsAttention,
          lastError: 'No MutationAdapter for ${item.type}',
        ),
      );
      telemetry.outboxFailed(item.type, 'missing_adapter');
      return;
    }

    var working = item.copyWith(
      status: OutboxItemStatus.flushing,
      attempts: item.attempts + 1,
    );
    await outbox.update(userId: userId, item: working);

    final result = await adapter.flush(working);
    switch (result.status) {
      case FlushStatus.success:
        if (result.serverId != null) {
          await adapter.reconcileServerIds(
            working.clientMutationId,
            result.serverId!,
          );
        }
        await outbox.update(
          userId: userId,
          item: working.copyWith(
            status: OutboxItemStatus.done,
            serverId: result.serverId,
          ),
        );
        telemetry.outboxFlushed(working.type);
        reachability.reportNetworkSuccess();
      case FlushStatus.retryableFailure:
        final next = working.attempts >= OutboxQueue.maxAttempts
            ? OutboxItemStatus.needsAttention
            : OutboxItemStatus.failed;
        await outbox.update(
          userId: userId,
          item: working.copyWith(
            status: next,
            lastError: result.errorMessage,
          ),
        );
        telemetry.outboxFailed(working.type, result.errorMessage ?? 'retryable');
        reachability.reportNetworkFailure();
      case FlushStatus.permanentFailure:
        await outbox.update(
          userId: userId,
          item: working.copyWith(
            status: OutboxItemStatus.needsAttention,
            lastError: result.errorMessage,
          ),
        );
        telemetry.outboxFailed(working.type, result.errorMessage ?? 'permanent');
      case FlushStatus.conflict:
        await outbox.update(
          userId: userId,
          item: working.copyWith(
            status: OutboxItemStatus.needsAttention,
            lastError: result.errorMessage,
          ),
        );
        _conflictController.add(
          result.errorMessage ?? 'Updated on another device',
        );
        telemetry.outboxFailed(working.type, 'conflict');
    }
  }

  Future<void> clearUser(String userId) async {
    await store.clearUser(userId);
    await outbox.clearUser(userId);
    for (final adapter in _snapshots.values) {
      await adapter.clearUser(userId);
    }
    _overlayShownUsers.remove(userId);
    _conflictController.add(null);
  }

  Future<int> approximateOfflineBytes() async {
    final userId = currentUserId;
    if (userId == null) return 0;
    return store.approximateUserBytes(userId);
  }

  Future<void> dispose() async {
    await _onlineSub?.cancel();
    await reachability.dispose();
    await outbox.dispose();
    await _conflictController.close();
  }
}
