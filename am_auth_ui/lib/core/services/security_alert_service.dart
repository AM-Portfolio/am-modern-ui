import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;

import '../../features/authentication/data/datasources/login_sessions_remote_datasource.dart';
import '../../features/authentication/data/models/security_event_model.dart';

typedef TabVisibleCheck = bool Function();

class SecurityAlertService {
  SecurityAlertService({
    required SecurityEventsApi dataSource,
    TabVisibleCheck? isTabVisible,
    Duration pollInterval = const Duration(seconds: 60),
  })  : _dataSource = dataSource,
        _isTabVisible = isTabVisible ?? _defaultTabVisible,
        _pollInterval = pollInterval;

  final SecurityEventsApi _dataSource;
  final TabVisibleCheck _isTabVisible;
  final Duration _pollInterval;

  final StreamController<List<SecurityEventModel>> _eventsController =
      StreamController<List<SecurityEventModel>>.broadcast();

  Timer? _pollTimer;
  double? _lastSeenAt;
  bool _running = false;

  Stream<List<SecurityEventModel>> get events => _eventsController.stream;

  static bool _defaultTabVisible() => kIsWeb;

  void start() {
    if (!kIsWeb || _running) return;
    _running = true;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollIfVisible());
    unawaited(_pollIfVisible());
  }

  void stop() {
    _running = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> onTabVisible() async {
    if (!kIsWeb) return;
    await _pollIfVisible();
  }

  Future<void> acknowledge(String eventId) async {
    await _dataSource.acknowledgeSecurityEvent(eventId);
    await _pollIfVisible();
  }

  @visibleForTesting
  Future<void> pollNow() => _pollIfVisible();

  Future<void> _pollIfVisible() async {
    if (!_isTabVisible()) return;
    try {
      final events = await _dataSource.listSecurityEvents(since: _lastSeenAt);
      final unread = events
          .where(
            (event) =>
                !event.acknowledged && event.type == 'new_device_login',
          )
          .toList();
      if (events.isNotEmpty) {
        _lastSeenAt = events
            .map((event) => event.createdAt)
            .reduce((a, b) => a > b ? a : b);
      }
      if (!_eventsController.isClosed) {
        _eventsController.add(unread);
      }
    } catch (_) {}
  }

  void dispose() {
    stop();
    _eventsController.close();
  }
}
