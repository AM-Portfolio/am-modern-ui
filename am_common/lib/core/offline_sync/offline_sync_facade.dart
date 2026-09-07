import 'package:get_it/get_it.dart';

import 'offline_sync_engine.dart';
import 'offline_widget_policy.dart';

/// Central entry for every feature package.
///
/// Repositories/UI call this instead of GrowthBook or connectivity directly:
/// ```dart
/// if (OfflineSync.shouldServeCache(OfflineWidgetId.portfolioHoldings)) {
///   return cached;
/// }
/// OfflineSync.reportNetworkFailure();
/// ```
class OfflineSync {
  OfflineSync._();

  static OfflineSyncEngine? get _engine {
    if (!GetIt.instance.isRegistered<OfflineSyncEngine>()) return null;
    return GetIt.instance<OfflineSyncEngine>();
  }

  static bool get isOnline => _engine?.isOnline ?? true;

  static bool get readsEnabled => _engine?.readsEnabled ?? false;

  static bool get writesEnabled => _engine?.writesEnabled ?? false;

  /// True when this widget may return local cache on network failure.
  static bool shouldServeCache(OfflineWidgetId id) {
    final engine = _engine;
    if (engine == null) return false;
    return engine.shouldServeCache(id);
  }

  /// True when UI should hide this widget while offline.
  static bool shouldHideWhenOffline(OfflineWidgetId id) {
    final engine = _engine;
    if (engine == null) return false;
    return engine.shouldHideWhenOffline(id);
  }

  /// True when mutations for this widget may enqueue to the outbox.
  static bool allowQueuedWrites(OfflineWidgetId id) {
    final engine = _engine;
    if (engine == null) return false;
    return engine.allowQueuedWrites(id);
  }

  static void reportNetworkFailure() => _engine?.reportNetworkFailure();

  static void reportNetworkSuccess() => _engine?.reportNetworkSuccess();

  static OfflineWidgetPolicy? policyFor(OfflineWidgetId id) =>
      _engine?.config.policyFor(id);
}
