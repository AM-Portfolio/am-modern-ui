import 'package:am_library/am_library.dart';

import 'offline_sync_config.dart';

class OfflineSyncTelemetry {
  OfflineSyncTelemetry(this._config);

  final OfflineSyncConfig _config;

  void _emit(String action, [Map<String, dynamic>? metadata]) {
    if (!_config.telemetryEnabled) return;
    ProductTelemetry.instance.featureAction(
      action,
      tag: 'offline_sync',
      metadata: metadata,
    );
  }

  void cacheHit(String domainId) =>
      _emit('offline_cache_hit', {'domainId': domainId});

  void cacheMiss(String domainId) =>
      _emit('offline_cache_miss', {'domainId': domainId});

  void outboxEnqueued(String type) =>
      _emit('outbox_enqueued', {'type': type});

  void outboxFlushed(String type) =>
      _emit('outbox_flushed', {'type': type});

  void outboxFailed(String type, String reason) =>
      _emit('outbox_failed', {'type': type, 'reason': reason});

  void shellShown() => _emit('offline_shell_shown');
}
