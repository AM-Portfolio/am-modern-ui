import 'dart:convert';
import 'package:am_library/am_library.dart';
import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/activity_item.dart';
import 'package:am_dashboard_ui/domain/models/allocation_response.dart';
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
      final summary = await _apiClient.get(
        '/v1/analysis/dashboard/summary',
        queryParams: {'arg0': userId},
        parser: (data) => DashboardSummary.fromJson(data),
      );
      AppLogger.info('✅ Dashboard Summary fetched: Value=${summary.totalValue}, Portfolios=${summary.totalPortfolios}');
      return summary;
    } catch (e) {
      AppLogger.error('Failed to fetch dashboard summary, using empty fallback', error: e);
      return const DashboardSummary(
        totalValue: 0.0,
        totalInvested: 0.0,
        totalGainLoss: 0.0,
        totalGainLossPercentage: 0.0,
        dayChange: 0.0,
        dayChangePercentage: 0.0,
        totalPortfolios: 0,
      );
    }
  }

  Future<List<PortfolioOverview>> getPortfolioOverviews(String userId) async {
    try {
      return await _apiClient.get(
        '/v1/analysis/dashboard/portfolio-overviews',
        queryParams: {'arg0': userId},
        parser: (data) => (data as List).map((e) => PortfolioOverview.fromJson(e)).toList(),
      );
    } catch (e) {
      AppLogger.error('Failed to fetch portfolio overviews, using empty fallback', error: e);
      return [];
    }
  }

  Future<AllocationResponse> getAllocation(String userId, {String groupBy = 'SECTOR'}) async {
    try {
      return await _apiClient.get(
        '/v1/analysis/PORTFOLIO/$userId/allocation',
        queryParams: {'groupBy': groupBy},
        parser: (data) => AllocationResponse.fromJson(data),
      );
    } catch (e) {
      AppLogger.error('Failed to fetch dashboard allocation, using empty fallback', error: e);
      return const AllocationResponse(
        sectors: [],
        assetClasses: [],
        marketCaps: [],
        stocks: [],
      );
    }
  }

  Future<TopMoversResponse> getTopMovers(String userId, {String timeFrame = '1D'}) async {
    try {
      return await _apiClient.get(
        '/v1/analysis/dashboard/top-movers',
        queryParams: {'arg0': userId, 'arg1': timeFrame},
        parser: (data) => TopMoversResponse.fromJson(data),
      );
    } catch (e) {
      AppLogger.error('Failed to fetch top movers, using empty fallback', error: e);
      return const TopMoversResponse(
        gainers: [],
        losers: [],
      );
    }
  }

  Future<PerformanceResponse> getPerformance(String userId, {String timeFrame = '1M'}) async {
    try {
      return await _apiClient.get(
        '/v1/analysis/PORTFOLIO/$userId/performance',
        queryParams: {'timeFrame': timeFrame},
        parser: (data) {
          // Provide defaults for required fields if backend returns null
          final sanitized = Map<String, dynamic>.from(data);
          sanitized['portfolioId'] ??= '';
          sanitized['timeFrame'] ??= timeFrame;
          sanitized['totalReturnPercentage'] ??= 0.0;
          sanitized['totalReturnValue'] ??= 0.0;
          return PerformanceResponse.fromJson(sanitized);
        },
      );
    } catch (e) {
      AppLogger.error('Failed to fetch performance chart, using empty fallback', error: e);
      return PerformanceResponse(
        portfolioId: '',
        timeFrame: timeFrame,
        totalReturnPercentage: 0.0,
        totalReturnValue: 0.0,
        chartData: [],
      );
    }
  }

  Future<List<ActivityItem>> getRecentActivity(String userId) async {
    try {
      return await _apiClient.get(
        '/v1/analysis/dashboard/recent-activity',
        queryParams: {'arg0': userId},
        parser: (data) {
          // The backend returns a RecentActivityResponse object containing an 'items' list
          final items = data['items'] as List?;
          return items?.map((e) {
            final json = e as Map<String, dynamic>;
            
            // If it's a HOLDING and amount/isPositive are missing, populate them for UI
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
        },
      );
    } catch (e) {
      AppLogger.error('Failed to fetch recent activity, using empty fallback', error: e);
      return [];
    }
  }

  Stream<DashboardSummary> getDashboardStream(String userId) {
    final destination = '/topic/dashboard/$userId';
    
    // Ensure subscription to the result topic
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

  void unsubscribeFromDashboardStream(String userId) {
    final destination = '/topic/dashboard/$userId';
    AppLogger.info('Unsubscribing from dashboard stream: $destination');
    _stompClient.unsubscribe(destination);
  }
}


