import 'dart:async';

import 'package:am_library/am_library.dart';
import 'package:rxdart/rxdart.dart';

import 'market_status.dart';
import 'market_status_client.dart';

/// Global gate: when closed, UI must stop STOMP interest / heartbeats.
/// REST and OHLC stay allowed. Fail-open on status fetch errors.
class MarketStreamingGate {
  MarketStreamingGate({
    MarketStatusClient? client,
    MarketStatusFetcher? fetchStatus,
  }) : _client = client ??
            MarketStatusClient(
              fetchOverride: fetchStatus,
            );

  final MarketStatusClient _client;

  static const Duration _istOffset = Duration(hours: 5, minutes: 30);

  final BehaviorSubject<bool> _isOpenSubject =
      BehaviorSubject<bool>.seeded(true);

  MarketStatus? _status;
  DateTime? _lastFetchedAt;
  Timer? _sessionTimer;
  bool _started = false;
  bool _refreshing = false;

  bool get isOpen => _isOpenSubject.value;

  Stream<bool> get isOpenStream => _isOpenSubject.stream.distinct();

  MarketStatus? get status => _status;

  /// Starts the gate once per login — fetches status if not cached.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await refresh(force: _status == null);
  }

  /// Pauses session-boundary timers (e.g. logout). Keeps cached status.
  void stop() {
    _started = false;
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  /// Logout: tear down timers and cached status so the next login refetches.
  void reset() {
    stop();
    _status = null;
    _lastFetchedAt = null;
    if (!_isOpenSubject.isClosed) {
      _isOpenSubject.add(true);
    }
  }

  Future<void> refresh({bool force = false}) async {
    if (_refreshing) return;
    if (!force &&
        _status != null &&
        _lastFetchedAt != null &&
        DateTime.now().difference(_lastFetchedAt!) <
            const Duration(hours: 1)) {
      return;
    }
    _refreshing = true;
    try {
      final next = await _client.fetchStatus(exchange: 'NSE');
      _status = next;
      _lastFetchedAt = DateTime.now();
      _setOpen(next.open);
      _scheduleSessionBoundary(next);
    } catch (e, st) {
      AppLogger.warning(
        'MarketStreamingGate: status fetch failed — keeping streaming allowed',
        tag: 'MarketStreamingGate',
      );
      AppLogger.debug('$e\n$st', tag: 'MarketStreamingGate');
      _schedulePollOnly();
    } finally {
      _refreshing = false;
    }
  }

  void _setOpen(bool open) {
    if (_isOpenSubject.isClosed) return;
    if (_isOpenSubject.value == open) return;
    AppLogger.info(
      'MarketStreamingGate: market ${open ? 'OPEN' : 'CLOSED'}'
      '${_status != null ? ' (${_status!.reason})' : ''}',
      tag: 'MarketStreamingGate',
    );
    _isOpenSubject.add(open);
  }

  void _schedulePollOnly() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  void _scheduleSessionBoundary(MarketStatus status) {
    _sessionTimer?.cancel();
    _sessionTimer = null;

    final nowIst = _nowIst();
    Duration? delay;

    if (status.open) {
      delay = _durationUntilTodayTime(status.sessionEnd, nowIst);
    } else {
      delay = _durationUntilTodayTime(status.sessionStart, nowIst);
      if (delay == null || delay <= Duration.zero) {
        delay = _durationUntilTomorrowTime(status.sessionStart, nowIst);
      }
    }

    if (delay == null || delay <= Duration.zero) return;

    final capped = delay > const Duration(hours: 24)
        ? const Duration(hours: 24)
        : delay;
    _sessionTimer = Timer(capped, () {
      unawaited(refresh());
    });
  }

  static DateTime _nowIst() => DateTime.now().toUtc().add(_istOffset);

  static Duration? _durationUntilTodayTime(String? hhmmss, DateTime nowIst) {
    final parts = _parseHms(hhmmss);
    if (parts == null) return null;
    final target = DateTime(
      nowIst.year,
      nowIst.month,
      nowIst.day,
      parts.$1,
      parts.$2,
      parts.$3,
    );
    return target.difference(nowIst);
  }

  static Duration? _durationUntilTomorrowTime(
    String? hhmmss,
    DateTime nowIst,
  ) {
    final parts = _parseHms(hhmmss);
    if (parts == null) return null;
    final tomorrow = nowIst.add(const Duration(days: 1));
    final target = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      parts.$1,
      parts.$2,
      parts.$3,
    );
    return target.difference(nowIst);
  }

  static (int, int, int)? _parseHms(String? value) {
    if (value == null || value.isEmpty) return null;
    final cleaned = value.length >= 8 ? value.substring(0, 8) : value;
    final bits = cleaned.split(':');
    if (bits.length < 2) return null;
    final h = int.tryParse(bits[0]);
    final m = int.tryParse(bits[1]);
    final s = bits.length > 2 ? int.tryParse(bits[2]) ?? 0 : 0;
    if (h == null || m == null) return null;
    return (h, m, s);
  }

  void dispose() {
    stop();
    if (!_isOpenSubject.isClosed) {
      _isOpenSubject.close();
    }
  }
}
