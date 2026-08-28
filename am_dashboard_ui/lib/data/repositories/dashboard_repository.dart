import 'dart:async';
import 'dart:convert';
import 'package:am_common/am_common.dart';
import 'package:get_it/get_it.dart';
import 'package:am_dashboard_ui/data/repositories/dashboard_json_sanitizer.dart';
import 'package:am_dashboard_ui/domain/models/activity_item.dart';
import 'package:am_dashboard_ui/domain/models/recent_activity_response.dart';
import 'package:am_dashboard_ui/domain/models/allocation_response.dart';
import 'package:am_dashboard_ui/domain/models/dashboard_summary.dart';
import 'package:am_dashboard_ui/domain/models/performance_response.dart';
import 'package:am_dashboard_ui/domain/models/portfolio_overview.dart';
import 'package:am_dashboard_ui/domain/models/top_movers_response.dart';
import 'package:am_dashboard_ui/domain/models/overlay_chart_models.dart';
import 'package:am_dashboard_ui/domain/models/overlay_history_parser.dart';

/// STOMP destinations for per-widget dashboard streaming (gateway relay).
class DashboardQueueDestinations {
  static const summary = '/user/queue/dashboard/summary';
  static const activity = '/user/queue/dashboard/activity';
  static const allocation = '/user/queue/dashboard/allocation';
  static const movers = '/user/queue/dashboard/movers';
  static const history = '/user/queue/dashboard/history';

  static const all = [summary, activity, allocation, movers, history];
}

class DashboardRepository {
  final ApiClient _apiClient;
  final AmStompClient _stompClient;

  bool _dashboardSubscribed = false;
  bool _wantsDashboardStream = false;
  StreamSubscription<StompStatus>? _statusSubscription;
  StreamSubscription<bool>? _marketGateSubscription;
  StreamingHeartbeatService? _heartbeat;

  DashboardRepository(this._apiClient, this._stompClient);

  void _ensureReconnectListener() {
    _statusSubscription ??= _stompClient.status.listen((status) {
      if (status == StompStatus.disconnected || status == StompStatus.error) {
        _dashboardSubscribed = false;
        AppLogger.info('Dashboard STOMP disconnected — will resubscribe on reconnect');
      } else if (status == StompStatus.connected &&
          _wantsDashboardStream &&
          !_dashboardSubscribed &&
          _isMarketStreamingOpen) {
        unawaited(subscribeToDashboard(forceResubscribe: true));
      }
    });
    _ensureMarketGateListener();
  }

  bool get _isMarketStreamingOpen {
    if (!GetIt.I.isRegistered<MarketStreamingGate>()) return true;
    return GetIt.I<MarketStreamingGate>().isOpen;
  }

  void _ensureMarketGateListener() {
    if (_marketGateSubscription != null) return;
    if (!GetIt.I.isRegistered<MarketStreamingGate>()) return;
    final gate = GetIt.I<MarketStreamingGate>();
    _marketGateSubscription = gate.isOpenStream.listen((open) {
      if (!_wantsDashboardStream) return;
      if (open) {
        unawaited(subscribeToDashboard(forceResubscribe: true));
      } else {
        pauseDashboardStreaming();
      }
    });
  }

  void dispose() {
    _heartbeat?.dispose();
    _statusSubscription?.cancel();
    _statusSubscription = null;
    _marketGateSubscription?.cancel();
    _marketGateSubscription = null;
  }

  Future<void> ensureStompConnected({int maxAttempts = 30}) async {
    for (var i = 0; i < maxAttempts; i++) {
      if (_stompClient.isConnected) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('STOMP not connected');
  }

  /// Registers dashboard watch channel when STOMP is up; logs and continues if not.
  Future<void> subscribeToDashboard({bool forceResubscribe = false}) async {
    _ensureReconnectListener();
    _wantsDashboardStream = true;

    if (!_isMarketStreamingOpen) {
      AppLogger.info(
        'Dashboard STOMP subscribe deferred — market closed',
      );
      return;
    }

    if (!_stompClient.isConnected) {
      AppLogger.warning(
        'Dashboard STOMP subscribe skipped — broker not connected yet',
      );
      return;
    }
    for (final destination in DashboardQueueDestinations.all) {
      _stompClient.subscribe(destination, forceResubscribe: forceResubscribe);
    }
    _stompClient.send(
      destination: '/app/dashboard/subscribe',
      headers: {'content-type': 'application/json'},
      body: '{}',
    );
    _dashboardSubscribed = true;
    _heartbeat ??= StreamingHeartbeatService(_stompClient);
    _heartbeat!.start();
    AppLogger.info('Dashboard STOMP subscribe sent; queues: ${DashboardQueueDestinations.all}');
  }

  Future<void> trySubscribeToDashboard({Duration timeout = const Duration(seconds: 30)}) async {
    _ensureReconnectListener();
    _wantsDashboardStream = true;

    if (_stompClient.isConnected) {
      await subscribeToDashboard(forceResubscribe: true);
      return;
    }
    try {
      await _stompClient.status
          .firstWhere((status) => status == StompStatus.connected)
          .timeout(timeout);
      await subscribeToDashboard(forceResubscribe: true);
    } on TimeoutException {
      AppLogger.warning(
        'Dashboard STOMP subscribe timed out after ${timeout.inSeconds}s — REST widgets will still load',
      );
    }
  }

  void unsubscribeFromDashboard() {
    if (!_dashboardSubscribed && !_wantsDashboardStream) return;
    _wantsDashboardStream = false;
    pauseDashboardStreaming();
  }

  /// Stops live interest/heartbeats but keeps [_wantsDashboardStream] so reopen resumes.
  void pauseDashboardStreaming() {
    if (!_dashboardSubscribed) {
      _heartbeat?.stop();
      return;
    }
    _heartbeat?.stop();
    for (final destination in DashboardQueueDestinations.all) {
      _stompClient.unsubscribe(destination);
    }
    if (_stompClient.isConnected) {
      _stompClient.send(
        destination: '/app/dashboard/unsubscribe',
        headers: {'content-type': 'application/json'},
        body: '{}',
      );
    }
    _dashboardSubscribed = false;
    AppLogger.info('Dashboard STOMP paused (market closed or tab left)');
  }

  Future<DashboardSummary> getSummary(String userId) async {
    try {
      return await _apiClient.get(
        '/v1/analysis/dashboard/summary',
        timeout: const Duration(seconds: 45),
        parser: (data) {
          try {
            return DashboardSummary.fromJson(
              DashboardJsonSanitizer.summary(data),
            );
          } catch (parseError) {
            AppLogger.error(
              'Dashboard summary JSON parse failed',
              error: parseError,
            );
            rethrow;
          }
        },
      );
    } catch (e) {
      AppLogger.error('Failed to fetch dashboard summary', error: e);
      rethrow;
    }
  }

  Future<List<PortfolioOverview>> getPortfolioOverviews(String userId) async {
    try {
      return await _apiClient.get(
        '/v1/analysis/dashboard/portfolio-overviews',
        parser: (data) => (data as List).map((e) => PortfolioOverview.fromJson(e)).toList(),
      );
    } catch (e) {
      AppLogger.error('Failed to fetch portfolio overviews', error: e);
      rethrow;
    }
  }

  Future<AllocationResponse> getAllocation(String userId, {String groupBy = 'SECTOR'}) async {
    try {
      return await _apiClient.get(
        '/v1/analysis/PORTFOLIO/ALL/allocation',
        queryParams: {'groupBy': groupBy},
        parser: (data) => AllocationResponse.fromJson(
          DashboardJsonSanitizer.allocation(data as Map<String, dynamic>),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to fetch dashboard allocation', error: e);
      rethrow;
    }
  }

  Future<TopMoversResponse> getTopMovers(String userId, {String timeFrame = '1D'}) async {
    try {
      return await _apiClient.get(
        '/v1/analysis/dashboard/top-movers',
        queryParams: {'timeFrame': timeFrame},
        parser: (data) => TopMoversResponse.fromJson(
          DashboardJsonSanitizer.topMovers(data as Map<String, dynamic>),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to fetch top movers', error: e);
      rethrow;
    }
  }

  Future<PerformanceResponse> getPerformance(String userId, {String timeFrame = '1M'}) async {
    try {
      return await _apiClient.get(
        '/v1/analysis/dashboard/performance',
        queryParams: {'timeFrame': timeFrame},
        timeout: const Duration(seconds: 15),
        parser: (data) => PerformanceResponse.fromJson(
          DashboardJsonSanitizer.performance(
            data as Map<String, dynamic>,
            defaultTimeFrame: timeFrame,
          ),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to fetch performance chart', error: e);
      rethrow;
    }
  }

  Future<RecentActivityResponse> getRecentActivity(
    String userId, {
    int page = 0,
    int size = 10,
    String sortBy = 'TIMESTAMP',
  }) async {
    try {
      return await _apiClient.get(
        '/v1/analysis/dashboard/recent-activity',
        queryParams: {
          'page': page.toString(),
          'size': size.toString(),
          'sortBy': sortBy,
        },
        parser: (data) => _parseRecentActivity(data),
      );
    } catch (e) {
      AppLogger.error('Failed to fetch recent activity', error: e);
      rethrow;
    }
  }

  Stream<DashboardSummary> watchSummary() => _watchWidget(
        DashboardQueueDestinations.summary,
        (json) => DashboardSummary.fromJson(DashboardJsonSanitizer.summary(json)),
      );

  Stream<List<ActivityItem>> watchActivity() => _watchWidget(
        DashboardQueueDestinations.activity,
        (json) => _parseRecentActivity(json).items,
      );

  Stream<AllocationResponse> watchAllocation() => _watchWidget(
        DashboardQueueDestinations.allocation,
        (json) => AllocationResponse.fromJson(DashboardJsonSanitizer.allocation(json)),
      );

  Stream<TopMoversResponse> watchMovers({String? timeFrame}) => _watchWidget(
        DashboardQueueDestinations.movers,
        (json) {
          final payload = json.containsKey('data') && json['data'] is Map
              ? Map<String, dynamic>.from(json['data'] as Map)
              : json;
          return TopMoversResponse.fromJson(
            DashboardJsonSanitizer.topMovers(payload),
          );
        },
      ).where((response) {
        if (timeFrame == null || timeFrame.isEmpty) return true;
        return response.timeFrame.isEmpty || response.timeFrame == timeFrame;
      });

  Stream<PerformanceResponse> watchHistory() => _watchWidget(
        DashboardQueueDestinations.history,
        (json) => PerformanceResponse.fromJson(
          DashboardJsonSanitizer.performance(json, defaultTimeFrame: '1D'),
        ),
      );

  Stream<T> _watchWidget<T>(String destination, T Function(Map<String, dynamic>) parser) {
    return _stompClient.messages
        .where((frame) => _matchesDestination(frame.headers['destination'], destination))
        .map((frame) => _tryParseWidgetFrame<T>(destination, frame, parser))
        .where((parsed) => parsed != null)
        .cast<T>()
        .handleError((Object error, StackTrace stack) {
          AppLogger.error('Error in dashboard stream $destination', error: error);
        });
  }

  T? _tryParseWidgetFrame<T>(
    String destination,
    dynamic frame,
    T Function(Map<String, dynamic>) parser,
  ) {
    final body = frame.body;
    if (body == null || body.isEmpty) {
      AppLogger.warning('Empty dashboard frame on $destination — skipped');
      return null;
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        AppLogger.warning('Non-object dashboard frame on $destination — skipped');
        return null;
      }
      final parsed = parser(DashboardJsonSanitizer.asObject(decoded));
      AppLogger.info('Dashboard widget update received: ${_widgetLabel(destination)}');
      return parsed;
    } catch (e) {
      AppLogger.error('Failed to parse dashboard frame on $destination', error: e);
      return null;
    }
  }

  String _widgetLabel(String destination) {
    if (destination.contains('/summary')) return 'summary';
    if (destination.contains('/activity')) return 'activity';
    if (destination.contains('/allocation')) return 'allocation';
    if (destination.contains('/movers')) return 'movers';
    if (destination.contains('/history')) return 'history';
    return destination;
  }

  bool _matchesDestination(String? actual, String expected) {
    if (actual == null || actual.isEmpty) return false;
    if (actual == expected) return true;
    final bare = expected.replaceFirst('/user', '');
    if (actual == bare || actual.endsWith(bare)) return true;
    final suffix = expected.split('/dashboard/').last;
    return actual.contains('/dashboard/$suffix');
  }

  RecentActivityResponse _parseRecentActivity(dynamic data) {
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final payload = map.containsKey('data') && map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;
    final items = _parseActivityItems(payload);
    return RecentActivityResponse(
      items: items,
      page: (payload['page'] as num?)?.toInt() ?? 0,
      size: (payload['size'] as num?)?.toInt() ?? items.length,
      totalItems: (payload['totalItems'] as num?)?.toInt() ?? items.length,
      totalPages: (payload['totalPages'] as num?)?.toInt() ?? 1,
      hasNext: payload['hasNext'] as bool? ?? false,
      hasPrevious: payload['hasPrevious'] as bool? ?? false,
    );
  }

  List<ActivityItem> _parseActivityItems(dynamic data) {
    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
    final items = map['items'] as List?;
    return items?.map((e) {
      final json = DashboardJsonSanitizer.activityItem(
        Map<String, dynamic>.from(e as Map),
      );
      if (json['type'] == 'HOLDING' && json['amount'] == null) {
        final currentValue = json['currentValue'] as double?;
        final profitLoss = json['profitLoss'] as double?;
        if (currentValue != null) {
          json['amount'] = '₹${currentValue.toStringAsFixed(2)}';
        }
        if (profitLoss != null) {
          json['isPositive'] = profitLoss >= 0;
        }
      }
      return ActivityItem.fromJson(json);
    }).toList() ?? [];
  }

  /// Same feed as the portfolio history chart (`GET /v1/portfolios/history`).
  /// 1D uses `/v1/portfolios/intraday`.
  Future<PortfolioOverlayHistory> getPortfolioHistory(
    ApiClient portfolioClient, {
    required String timeFrame,
  }) async {
    final isIntraday = timeFrame.toUpperCase() == '1D';
    final path = isIntraday ? '/v1/portfolios/intraday' : '/v1/portfolios/history';
    try {
      final data = await portfolioClient.get(
        path,
        queryParams: isIntraday ? null : {'timeFrame': timeFrame},
        parser: (raw) => raw,
      );
      return parsePortfolioOverlayHistory(data, isIntraday: isIntraday);
    } catch (e) {
      AppLogger.error('Failed to fetch portfolio history for overlay', error: e);
      rethrow;
    }
  }

  /// Same feed as the market multi-index chart (`GET /v1/analysis/historical-charts`).
  Future<Map<String, List<OverlayPoint>>> getIndexHistory(
    ApiClient marketClient, {
    required List<String> symbols,
    required String range,
  }) async {
    if (symbols.isEmpty) return {};
    try {
      final data = await marketClient.get(
        '/v1/analysis/historical-charts',
        queryParams: {
          'symbols': symbols.join(','),
          'range': range,
        },
        parser: (raw) => raw,
      );
      return _parseIndexOverlayPoints(data, symbols);
    } catch (e) {
      AppLogger.error('Failed to fetch index history for overlay', error: e);
      rethrow;
    }
  }

  Map<String, List<OverlayPoint>> _parseIndexOverlayPoints(
    dynamic data,
    List<String> symbols,
  ) {
    final result = <String, List<OverlayPoint>>{};
    Map<String, dynamic>? bySymbol;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final inner = map['data'];
      if (inner is Map) {
        bySymbol = Map<String, dynamic>.from(inner);
      } else {
        bySymbol = map;
      }
    }
    if (bySymbol == null) return result;

    for (final symbol in symbols) {
      final entry = bySymbol[symbol] ??
          bySymbol.entries
              .where((e) => e.key.toUpperCase() == symbol.toUpperCase())
              .map((e) => e.value)
              .firstOrNull;
      if (entry is! Map) continue;
      final entryMap = Map<String, dynamic>.from(entry);
      final rawPoints =
          entryMap['dataPoints'] ?? entryMap['dataPoints'] ?? entryMap['data'];
      final rows = _asObjectList(rawPoints);
      final points = <OverlayPoint>[];
      for (final row in rows) {
        final label = _stringOf(row, const ['time', 'timestamp', 'date']);
        final value = _numOf(
          row,
          const ['close', 'price', 'lastPrice', 'value'],
        );
        if (value == null || !value.isFinite) continue;
        points.add(OverlayPoint(xLabel: label ?? '', value: value));
      }
      if (points.isNotEmpty) result[symbol] = points;
    }
    return result;
  }

  List<Map<String, dynamic>> _asObjectList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map && data['data'] is List) {
      return _asObjectList(data['data']);
    }
    return const [];
  }

  String? _stringOf(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  double? _numOf(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
    }
    return null;
  }
}
