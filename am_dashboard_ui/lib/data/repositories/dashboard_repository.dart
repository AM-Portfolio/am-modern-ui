import 'dart:async';
import 'dart:convert';
import 'package:am_library/am_library.dart';
import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/data/repositories/dashboard_json_sanitizer.dart';
import 'package:am_dashboard_ui/domain/models/activity_item.dart';
import 'package:am_dashboard_ui/domain/models/allocation_response.dart';
import 'package:am_dashboard_ui/domain/models/dashboard_summary.dart';
import 'package:am_dashboard_ui/domain/models/performance_response.dart';
import 'package:am_dashboard_ui/domain/models/portfolio_overview.dart';
import 'package:am_dashboard_ui/domain/models/top_movers_response.dart';

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

  DashboardRepository(this._apiClient, this._stompClient);

  Future<void> ensureStompConnected({int maxAttempts = 30}) async {
    for (var i = 0; i < maxAttempts; i++) {
      if (_stompClient.isConnected) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('STOMP not connected');
  }

  /// Registers dashboard watch channel when STOMP is up; logs and continues if not.
  Future<void> subscribeToDashboard() async {
    if (!_stompClient.isConnected) {
      AppLogger.warning(
        'Dashboard STOMP subscribe skipped — broker not connected yet',
      );
      return;
    }
    for (final destination in DashboardQueueDestinations.all) {
      _stompClient.subscribe(destination);
    }
    _stompClient.send(
      destination: '/app/dashboard/subscribe',
      headers: {'content-type': 'application/json'},
      body: '{}',
    );
    _dashboardSubscribed = true;
    AppLogger.info('Dashboard STOMP subscribe sent; queues: ${DashboardQueueDestinations.all}');
  }

  Future<void> trySubscribeToDashboard({int maxAttempts = 30}) async {
    for (var i = 0; i < maxAttempts; i++) {
      if (_stompClient.isConnected) {
        await subscribeToDashboard();
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    AppLogger.warning('Dashboard STOMP subscribe timed out — REST widgets will still load');
  }

  void unsubscribeFromDashboard() {
    if (!_dashboardSubscribed) return;
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
    AppLogger.info('Dashboard STOMP unsubscribed');
  }

  Future<DashboardSummary> getSummary(String userId) async {
    try {
      return await _apiClient.get(
        '/v1/analysis/dashboard/summary',
        parser: (data) => DashboardSummary.fromJson(data),
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

  Future<List<ActivityItem>> getRecentActivity(String userId) async {
    try {
      return await _apiClient.get(
        '/v1/analysis/dashboard/recent-activity',
        parser: (data) => _parseActivityItems(data),
      );
    } catch (e) {
      AppLogger.error('Failed to fetch recent activity', error: e);
      rethrow;
    }
  }

  Stream<DashboardSummary> watchSummary() => _watchWidget(
        DashboardQueueDestinations.summary,
        (json) => DashboardSummary.fromJson(json),
      );

  Stream<List<ActivityItem>> watchActivity() => _watchWidget(
        DashboardQueueDestinations.activity,
        (json) => _parseActivityItems(json),
      );

  Stream<AllocationResponse> watchAllocation() => _watchWidget(
        DashboardQueueDestinations.allocation,
        (json) => AllocationResponse.fromJson(DashboardJsonSanitizer.allocation(json)),
      );

  Stream<TopMoversResponse> watchMovers() => _watchWidget(
        DashboardQueueDestinations.movers,
        (json) => TopMoversResponse.fromJson(DashboardJsonSanitizer.topMovers(json)),
      );

  Stream<PerformanceResponse> watchHistory() => _watchWidget(
        DashboardQueueDestinations.history,
        (json) => PerformanceResponse.fromJson(
          DashboardJsonSanitizer.performance(json, defaultTimeFrame: '1D'),
        ),
      );

  Stream<T> _watchWidget<T>(String destination, T Function(Map<String, dynamic>) parser) {
    return _stompClient.messages
        .where((frame) => _matchesDestination(frame.headers['destination'], destination))
        .map((frame) {
          final body = frame.body;
          if (body == null || body.isEmpty) {
            throw StateError('Empty body on $destination');
          }
          try {
            final decoded = jsonDecode(body);
            if (decoded is! Map<String, dynamic>) {
              throw FormatException('Expected object on $destination');
            }
            return parser(decoded);
          } catch (e) {
            AppLogger.error('Failed to parse dashboard frame on $destination', error: e);
            rethrow;
          }
        })
        .handleError((Object error, StackTrace stack) {
          AppLogger.error('Error in dashboard stream $destination', error: error);
        });
  }

  bool _matchesDestination(String? actual, String expected) {
    if (actual == null || actual.isEmpty) return false;
    if (actual == expected) return true;
    final bare = expected.replaceFirst('/user', '');
    if (actual == bare || actual.endsWith(bare)) return true;
    final suffix = expected.split('/dashboard/').last;
    return actual.contains('/dashboard/$suffix');
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
}
