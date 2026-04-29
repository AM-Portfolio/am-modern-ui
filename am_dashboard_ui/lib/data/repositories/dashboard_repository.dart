import 'dart:convert';
import 'package:am_library/am_library.dart';
import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/activity_item.dart';
import 'package:am_dashboard_ui/domain/models/dashboard_summary.dart';
import 'package:am_dashboard_ui/domain/models/performance_response.dart';
import 'package:am_dashboard_ui/domain/models/portfolio_overview.dart';
import 'package:am_dashboard_ui/domain/models/top_movers_response.dart';

class DashboardRepository {
  final ApiClient _apiClient;
  final AmStompClient _stompClient;

  DashboardRepository(this._apiClient, this._stompClient);

  Future<DashboardSummary> getSummary(String userId) async {
    try {
      return await _apiClient.get(
        '/v1/analysis/dashboard/summary',
        queryParams: {'userId': userId},
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
        queryParams: {'userId': userId},
        parser: (data) => (data as List).map((e) => PortfolioOverview.fromJson(e)).toList(),
      );
    } catch (e) {
      AppLogger.error('Failed to fetch portfolio overviews', error: e);
      rethrow;
    }
  }

  Future<TopMoversResponse> getTopMovers(String userId, {String timeFrame = '1D'}) async {
    try {
      return await _apiClient.get(
        '/v1/analysis/dashboard/top-movers',
        queryParams: {'userId': userId, 'timeFrame': timeFrame},
        parser: (data) => TopMoversResponse.fromJson(data),
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
        queryParams: {'userId': userId, 'timeFrame': timeFrame},
        parser: (data) => PerformanceResponse.fromJson(data),
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
        queryParams: {'userId': userId},
        parser: (data) => (data as List).map((e) => ActivityItem.fromJson(e)).toList(),
      );
    } catch (e) {
      AppLogger.error('Failed to fetch recent activity', error: e);
      rethrow;
    }
  }

  Stream<DashboardSummary> getDashboardStream(String userId) {
    final destination = '/topic/dashboard/$userId';
    
    // Ensure subscription
    _stompClient.subscribe(destination);

    return _stompClient.messages
        .where((frame) => frame.headers['destination'] == destination)
        .map((frame) {
          if (frame.body == null) throw Exception('Empty body in dashboard update');
          
          final json = jsonDecode(frame.body!);
          return DashboardSummary.fromJson(json['summary']);
        })
        .handleError((error) {
          AppLogger.error('Error in dashboard stream', error: error);
        });
  }
}


