import 'package:am_dashboard_ui/data/repositories/dashboard_repository.dart';
import 'package:am_dashboard_ui/domain/models/activity_item.dart';
import 'package:am_dashboard_ui/domain/models/dashboard_summary.dart';
import 'package:am_dashboard_ui/domain/models/performance_response.dart';
import 'package:am_dashboard_ui/domain/models/portfolio_overview.dart';
import 'package:am_dashboard_ui/domain/models/top_movers_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:am_common/am_common.dart';

part 'dashboard_provider.g.dart';

@riverpod
Future<DashboardRepository> dashboardRepository(Ref ref) async {
  final apiClient = await ref.watch(analysisApiClientProvider.future);
  final stompClient = GetIt.I<AmStompClient>();
  return DashboardRepository(apiClient, stompClient);
}

@riverpod
Future<DashboardSummary> dashboardSummary(Ref ref, String userId) async {
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  return repository.getSummary(userId);
}

@riverpod
Stream<DashboardSummary> dashboardStream(Ref ref, String userId) async* {
  if (userId.isEmpty) {
    throw ArgumentError('User ID cannot be empty');
  }
  
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  
  // Yield initial data from REST to show something immediately
  try {
     final initial = await repository.getSummary(userId);
     yield initial;
  } catch (e) {
     AppLogger.error('Failed to fetch initial dashboard summary, but continuing to stream', error: e);
     // Rethrow if we want the UI to show an error immediately on first load failure
     rethrow; 
  }
  
  ref.onDispose(() {
    repository.unsubscribeFromDashboardStream(userId);
  });

  // Listen to WebSocket updates
  yield* repository.getDashboardStream(userId);
}

@riverpod
Future<List<PortfolioOverview>> portfolioOverviews(Ref ref, String userId) async {
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  return repository.getPortfolioOverviews(userId);
}

@riverpod
Future<TopMoversResponse> topMovers(Ref ref, String userId, {String timeFrame = '1D'}) async {
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  return repository.getTopMovers(userId, timeFrame: timeFrame);
}

@riverpod
Future<PerformanceResponse> dashboardPerformance(Ref ref, String userId, {String timeFrame = '1M'}) async {
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  return repository.getPerformance(userId, timeFrame: timeFrame);
}

@riverpod
Future<List<ActivityItem>> recentActivity(Ref ref, String userId) async {
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  return repository.getRecentActivity(userId);
}
