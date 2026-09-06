import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'offline_sync_engine.dart';
import 'offline_widget_policy.dart';

final offlineSyncEngineProvider = Provider<OfflineSyncEngine>((ref) {
  if (!GetIt.instance.isRegistered<OfflineSyncEngine>()) {
    throw StateError('OfflineSyncEngine is not registered');
  }
  return GetIt.instance<OfflineSyncEngine>();
});

final offlineIsOnlineProvider = StreamProvider<bool>((ref) {
  final engine = ref.watch(offlineSyncEngineProvider);
  return engine.isOnlineStream;
});

final offlinePendingCountProvider = StreamProvider<int>((ref) {
  final engine = ref.watch(offlineSyncEngineProvider);
  return engine.pendingCountStream;
});

final offlineConflictMessageProvider = StreamProvider<String?>((ref) {
  final engine = ref.watch(offlineSyncEngineProvider);
  return engine.conflictMessageStream;
});

/// Per-widget: hide this surface while offline (central config).
final offlineHideWidgetProvider =
    Provider.family<bool, OfflineWidgetId>((ref, id) {
  ref.watch(offlineIsOnlineProvider);
  final engine = ref.watch(offlineSyncEngineProvider);
  return engine.shouldHideWhenOffline(id);
});

/// Per-widget: cache-on-failure allowed (central config + reads flag).
final offlineCacheEnabledProvider =
    Provider.family<bool, OfflineWidgetId>((ref, id) {
  ref.watch(offlineIsOnlineProvider);
  final engine = ref.watch(offlineSyncEngineProvider);
  return engine.shouldServeCache(id);
});
