import 'dart:async';

import 'package:am_dashboard_ui/data/repositories/dashboard_repository.dart';
import 'package:am_dashboard_ui/domain/models/activity_item.dart';
import 'package:am_dashboard_ui/domain/models/allocation_response.dart';
import 'package:am_dashboard_ui/domain/models/dashboard_summary.dart';
import 'package:am_dashboard_ui/domain/models/performance_response.dart';
import 'package:am_dashboard_ui/domain/models/portfolio_overview.dart';
import 'package:am_dashboard_ui/domain/models/recent_activity_response.dart';
import 'package:am_dashboard_ui/domain/models/top_movers_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:am_common/am_common.dart';

part 'dashboard_provider.g.dart';

@Riverpod(keepAlive: true)
Future<DashboardRepository> dashboardRepository(Ref ref) async {
  final apiClient = await ref.watch(analysisApiClientProvider.future);
  final stompClient = GetIt.I<AmStompClient>();
  return DashboardRepository(apiClient, stompClient);
}

void _attachDashboardStreaming(Ref ref, String userId) {
  if (userId.isEmpty) return;
  unawaited(
    ref.read(dashboardStreamingSessionProvider(userId).future).catchError((_) {}),
  );
}

/// Starts dashboard STOMP session (subscribe + queue bindings). Watch from DashboardPage.
@riverpod
Future<void> dashboardStreamingSession(Ref ref, String userId) async {
  if (userId.isEmpty) return;
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  await repository.trySubscribeToDashboard();
  ref.onDispose(() {
    repository.unsubscribeFromDashboard();
  });
}

/// Eagerly starts all dashboard REST providers in parallel on mount.
@riverpod
void dashboardParallelKickoff(
  Ref ref,
  String userId, {
  String timeFrame = '1D',
}) {
  if (userId.isEmpty) return;
  ref.watch(dashboardStreamProvider(userId));
  ref.watch(historyStreamProvider(userId, timeFrame: timeFrame));
  ref.watch(moversStreamProvider(userId, timeFrame: timeFrame));
  ref.watch(portfolioOverviewsProvider(userId));
  ref.watch(recentActivityProvider(userId, page: 0, size: 10));
}

@riverpod
Future<DashboardSummary> dashboardSummary(Ref ref, String userId) async {
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  return repository.getSummary(userId);
}

@riverpod
Stream<DashboardSummary> dashboardStream(Ref ref, String userId) async* {
  if (userId.isEmpty) throw ArgumentError('User ID cannot be empty');

  final repository = await ref.watch(dashboardRepositoryProvider.future);
  yield await repository.getSummary(userId);

  _attachDashboardStreaming(ref, userId);
  try {
    yield* repository.watchSummary();
  } catch (e) {
    AppLogger.warning('Dashboard summary live stream unavailable', error: e);
  }
}

@riverpod
Stream<List<ActivityItem>> activityStream(Ref ref, String userId) async* {
  if (userId.isEmpty) throw ArgumentError('User ID cannot be empty');

  final repository = await ref.watch(dashboardRepositoryProvider.future);
  final initial = await repository.getRecentActivity(userId, size: 10);
  yield initial.items;

  _attachDashboardStreaming(ref, userId);
  try {
    yield* repository.watchActivity();
  } catch (e) {
    AppLogger.warning('Dashboard activity live stream unavailable', error: e);
  }
}

@riverpod
Stream<AllocationResponse> allocationStream(Ref ref, String userId) async* {
  if (userId.isEmpty) throw ArgumentError('User ID cannot be empty');

  final repository = await ref.watch(dashboardRepositoryProvider.future);
  yield await repository.getAllocation(userId);

  _attachDashboardStreaming(ref, userId);
  try {
    yield* repository.watchAllocation();
  } catch (e) {
    AppLogger.warning('Dashboard allocation live stream unavailable', error: e);
  }
}

@riverpod
Stream<TopMoversResponse> moversStream(Ref ref, String userId, {String timeFrame = '1D'}) async* {
  if (userId.isEmpty) throw ArgumentError('User ID cannot be empty');

  final repository = await ref.watch(dashboardRepositoryProvider.future);
  yield await repository.getTopMovers(userId, timeFrame: timeFrame);

  _attachDashboardStreaming(ref, userId);
  try {
    yield* repository.watchMovers(timeFrame: timeFrame);
  } catch (e) {
    AppLogger.warning('Dashboard movers live stream unavailable', error: e);
  }
}

@riverpod
Stream<PerformanceResponse> historyStream(Ref ref, String userId, {String timeFrame = '1D'}) async* {
  if (userId.isEmpty) throw ArgumentError('User ID cannot be empty');

  final repository = await ref.watch(dashboardRepositoryProvider.future);
  yield await repository.getPerformance(userId, timeFrame: timeFrame);

  _attachDashboardStreaming(ref, userId);
  try {
    yield* repository.watchHistory();
  } catch (e) {
    AppLogger.warning('Dashboard history live stream unavailable', error: e);
  }
}

@riverpod
Future<List<PortfolioOverview>> portfolioOverviews(Ref ref, String userId) async {
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  return repository.getPortfolioOverviews(userId);
}

// Legacy Future providers (REST-only fallbacks / refresh)
@riverpod
Future<AllocationResponse> dashboardAllocation(Ref ref, String userId) async {
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  return repository.getAllocation(userId);
}

@riverpod
Future<TopMoversResponse> topMovers(Ref ref, String userId, {String timeFrame = '1D'}) async {
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  return repository.getTopMovers(userId, timeFrame: timeFrame);
}

@riverpod
Future<PerformanceResponse> dashboardPerformance(Ref ref, String userId, {String timeFrame = '1D'}) async {
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  return repository.getPerformance(userId, timeFrame: timeFrame);
}

@riverpod
Future<RecentActivityResponse> recentActivity(
  Ref ref,
  String userId, {
  int page = 0,
  int size = 10,
  String sortBy = 'TIMESTAMP',
}) async {
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  return repository.getRecentActivity(
    userId,
    page: page,
    size: size,
    sortBy: sortBy,
  );
}
