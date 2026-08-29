import 'dart:async';

import 'package:am_dashboard_ui/data/repositories/dashboard_repository.dart';
import 'package:am_dashboard_ui/domain/models/activity_item.dart';
import 'package:am_dashboard_ui/domain/models/allocation_response.dart';
import 'package:am_dashboard_ui/domain/models/dashboard_summary.dart';
import 'package:am_dashboard_ui/domain/models/performance_response.dart';
import 'package:am_dashboard_ui/domain/models/portfolio_overview.dart';
import 'package:am_dashboard_ui/domain/models/recent_activity_response.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_provider.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_widget_id.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_overlay_provider.dart';
import 'package:am_dashboard_ui/domain/models/top_movers_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:am_common/am_common.dart';
import 'package:am_library/am_library.dart';

part 'dashboard_provider.g.dart';

/// Waits for auth restore on reload — route may pass empty userId while session
/// is still loading from secure storage.
@riverpod
Future<String> dashboardSessionUserId(Ref ref, String routeUserId) async {
  if (routeUserId.isNotEmpty) return routeUserId;
  for (var attempt = 0; attempt < 100; attempt++) {
    final id = await UserContext.instance.userId;
    if (id != null && id.isNotEmpty) return id;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw StateError('Dashboard session not ready');
}

Future<String> _requireDashboardUserId(Ref ref, String userId) async {
  if (userId.isNotEmpty) return userId;
  return ref.watch(dashboardSessionUserIdProvider('').future);
}

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

@riverpod
Future<ApiClient> portfolioApiClient(Ref ref) async {
  final config = await ref.watch(appConfigProvider.future);
  return ApiClient(baseUrl: config.api.portfolio.baseUrl);
}

/// Single shared fetch of portfolio summary used by all dashboard fallbacks.
@Riverpod(keepAlive: true)
Future<Map<String, dynamic>> portfolioSummaryFallback(Ref ref) async {
  final config = await ref.watch(appConfigProvider.future);
  final client = await ref.watch(portfolioApiClientProvider.future);
  return client.get(
    config.api.portfolio.summaryResource,
    parser: (data) {
      if (data is Map) return Map<String, dynamic>.from(data);
      throw const FormatException('Portfolio summary was not an object');
    },
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
  final visible =
      ref.watch(dashboardLayoutProvider).visibleSlots.map((s) => s.id).toSet();
  if (visible.contains(DashboardWidgetId.summary)) {
    ref.watch(dashboardStreamProvider(userId));
  }
  if (visible.contains(DashboardWidgetId.movers)) {
    ref.watch(moversStreamProvider(userId, timeFrame: timeFrame));
  }
  if (visible.contains(DashboardWidgetId.portfolioList)) {
    ref.watch(portfolioOverviewsProvider(userId));
  }
  if (visible.contains(DashboardWidgetId.recentActivity)) {
    ref.watch(recentActivityProvider(userId, page: 0, size: 10));
  }
  if (visible.contains(DashboardWidgetId.allocation)) {
    ref.watch(allocationStreamProvider(userId));
  }
  if (visible.contains(DashboardWidgetId.benchmarkComparison) ||
      visible.contains(DashboardWidgetId.portfolioWealthChart)) {
    ref.watch(dashboardOverlayProvider(userId));
  }
}

double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

DashboardSummary _dashboardSummaryFromPortfolioRaw(Map<String, dynamic> rawData) {
  final brokerPortfolios = rawData['brokerPortfolios'] is Map
      ? rawData['brokerPortfolios'] as Map
      : null;
  final brokers = rawData['brokers'];
  final totalPortfolios = brokerPortfolios?.keys.length ??
      (brokers is List ? brokers.length : 0);

  return DashboardSummary(
    totalValue: _parseDouble(rawData['currentValue'] ?? rawData['totalValue']),
    totalInvested: _parseDouble(
      rawData['investmentValue'] ?? rawData['totalInvested'],
    ),
    totalGainLoss: _parseDouble(rawData['totalGainLoss']),
    totalGainLossPercentage: _parseDouble(rawData['totalGainLossPercentage']),
    dayChange: _parseDouble(rawData['todayGainLoss'] ?? rawData['dayChange']),
    dayChangePercentage: _parseDouble(
      rawData['todayGainLossPercentage'] ?? rawData['dayChangePercentage'],
    ),
    totalPortfolios: totalPortfolios == 0 ? 1 : totalPortfolios,
  );
}

/// Retry clears keepAlive fallback too — otherwise a prior fallback error
/// sticks and Retry on the summary widget never recovers.
void retryDashboardSummary(WidgetRef ref, String userId) {
  ref.invalidate(portfolioSummaryFallbackProvider);
  ref.invalidate(dashboardSummaryProvider(userId));
  ref.invalidate(dashboardStreamProvider(userId));
}

Future<Map<String, dynamic>> _loadPortfolioSummaryFallback(Ref ref) async {
  // Prefer cached success. Only invalidate+retry when the keepAlive is in error
  // — always calling refresh() races when summary/overviews/history fall back
  // together and intermittently fails the header.
  final cached = ref.read(portfolioSummaryFallbackProvider);
  if (cached.hasValue) return cached.requireValue;
  if (cached.hasError) {
    ref.invalidate(portfolioSummaryFallbackProvider);
  }
  return ref.read(portfolioSummaryFallbackProvider.future);
}

Future<DashboardSummary> _resolveDashboardSummary(
  Ref ref,
  DashboardRepository repository,
  String userId,
) async {
  final portfolioFallback = _loadPortfolioSummaryFallback(ref)
      .then(_dashboardSummaryFromPortfolioRaw);

  try {
    return await repository
        .getSummary(userId)
        .timeout(const Duration(seconds: 20));
  } catch (e) {
    AppLogger.warning(
      'Failed to get summary from analysis service. Trying fallback to portfolio service...',
      error: e,
    );
    try {
      return await portfolioFallback.timeout(const Duration(seconds: 20));
    } catch (fallbackError) {
      // Last chance: fresh portfolio fetch (clears a poisoned keepAlive).
      ref.invalidate(portfolioSummaryFallbackProvider);
      try {
        final raw = await ref.read(portfolioSummaryFallbackProvider.future)
            .timeout(const Duration(seconds: 25));
        return _dashboardSummaryFromPortfolioRaw(raw);
      } catch (finalError) {
        AppLogger.error(
          'Dashboard summary fallback also failed',
          error: finalError,
        );
        rethrow;
      }
    }
  }
}

List<PortfolioOverview> _portfolioOverviewsFromPortfolioRaw(
  Map<String, dynamic> rawData,
) {
  return [
    PortfolioOverview(
      type: 'CONSOLIDATED',
      totalValue: _parseDouble(rawData['currentValue']),
      totalReturn: _parseDouble(rawData['totalGainLoss']),
      returnPercentage: _parseDouble(rawData['totalGainLossPercentage']),
      dayChange: _parseDouble(rawData['todayGainLoss']),
      dayChangePercentage: _parseDouble(rawData['todayGainLossPercentage']),
      portfolioCount: 1,
    ),
  ];
}

PerformanceResponse _performanceFromPortfolioRaw(
  Map<String, dynamic> rawData,
  String timeFrame,
) {
  return _generatePerformanceFromSummary(
    _parseDouble(rawData['currentValue']),
    _parseDouble(rawData['totalGainLoss']),
    _parseDouble(rawData['todayGainLoss']),
    timeFrame,
  );
}

PerformanceResponse _generatePerformanceFromSummary(double totalValue, double totalGainLoss, double todayGainLoss, String timeFrame) {
  final now = DateTime.now();
  final List<DataPoint> chartData = [];
  int pointsCount = 10;
  
  double rangeGainLoss = totalGainLoss;
  
  if (timeFrame == '1D') {
    pointsCount = 24;
    rangeGainLoss = todayGainLoss;
  } else if (timeFrame == '1W') {
    pointsCount = 7;
    rangeGainLoss = todayGainLoss * 3;
    if (totalGainLoss > 0 && rangeGainLoss.abs() > totalGainLoss.abs()) {
      rangeGainLoss = totalGainLoss * 0.25;
    }
  } else if (timeFrame == '1M') {
    pointsCount = 30;
    rangeGainLoss = totalGainLoss * 0.15;
  } else if (timeFrame == '3M') {
    pointsCount = 12;
    rangeGainLoss = totalGainLoss * 0.35;
  } else if (timeFrame == '6M') {
    pointsCount = 6;
    rangeGainLoss = totalGainLoss * 0.60;
  } else if (timeFrame == '1Y') {
    pointsCount = 12;
    rangeGainLoss = totalGainLoss * 0.85;
  } else {
    pointsCount = 5;
    rangeGainLoss = totalGainLoss;
  }
  
  final startValue = totalValue - rangeGainLoss;
  
  for (int i = 0; i < pointsCount; i++) {
    DateTime date;
    if (timeFrame == '1D') {
      date = now.subtract(Duration(hours: pointsCount - 1 - i));
    } else if (timeFrame == '1W') {
      date = now.subtract(Duration(days: pointsCount - 1 - i));
    } else if (timeFrame == '1M') {
      date = now.subtract(Duration(days: pointsCount - 1 - i));
    } else if (timeFrame == '3M') {
      date = now.subtract(Duration(days: (pointsCount - 1 - i) * 7));
    } else if (timeFrame == '6M' || timeFrame == '1Y') {
      date = DateTime(now.year, now.month - (pointsCount - 1 - i), now.day);
    } else {
      date = DateTime(now.year - (pointsCount - 1 - i), now.month, now.day);
    }
    
    // Create a smooth progressive look with a tiny bit of sine wave fluctuation
    final double fraction = i / (pointsCount - 1 == 0 ? 1 : pointsCount - 1);
    final double fluctuation = (i == pointsCount - 1) ? 0.0 : ((i % 2 == 0 ? 1.0 : -1.0) * (totalValue * 0.0015));
    final calculatedValue = startValue + (fraction * rangeGainLoss) + fluctuation;
    
    chartData.add(DataPoint(
      date: date.toIso8601String(),
      value: calculatedValue,
    ));
  }
  
  return PerformanceResponse(
    portfolioId: 'ALL',
    timeFrame: timeFrame,
    totalReturnPercentage: startValue > 0 ? (rangeGainLoss / startValue) * 100 : 0.0,
    totalReturnValue: rangeGainLoss,
    chartData: chartData,
  );
}

@riverpod
Future<DashboardSummary> dashboardSummary(Ref ref, String userId) async {
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  return _resolveDashboardSummary(ref, repository, userId);
}

@Riverpod(keepAlive: true)
Stream<DashboardSummary> dashboardStream(Ref ref, String userId) async* {
  final resolvedUserId = await _requireDashboardUserId(ref, userId);

  final repository = await ref.watch(dashboardRepositoryProvider.future);

  final summary = await _resolveDashboardSummary(ref, repository, resolvedUserId);
  yield summary;

  _attachDashboardStreaming(ref, resolvedUserId);
  try {
    await for (final next in repository.watchSummary()) {
      yield next;
    }
  } catch (e) {
    AppLogger.warning('Dashboard summary live stream unavailable', error: e);
  }
}

@riverpod
Stream<List<ActivityItem>> activityStream(Ref ref, String userId) async* {
  if (userId.isEmpty) throw ArgumentError('User ID cannot be empty');

  final repository = await ref.watch(dashboardRepositoryProvider.future);
  
  List<ActivityItem> items = [];
  try {
    final initial = await repository.getRecentActivity(userId, size: 10);
    items = initial.items;
  } catch (e) {
    AppLogger.warning('Failed to get initial recent activity, using empty list', error: e);
  }
  
  yield items;

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
  
  AllocationResponse allocation = const AllocationResponse();
  try {
    allocation = await repository.getAllocation(userId);
  } catch (e) {
    AppLogger.warning('Failed to get allocation from analysis service', error: e);
  }
  
  yield allocation;

  _attachDashboardStreaming(ref, userId);
  try {
    yield* repository.watchAllocation();
  } catch (e) {
    AppLogger.warning('Dashboard allocation live stream unavailable', error: e);
  }
}

@riverpod
Stream<TopMoversResponse> moversStream(Ref ref, String userId, {String timeFrame = '1D'}) async* {
  final resolvedUserId = await _requireDashboardUserId(ref, userId);

  final repository = await ref.watch(dashboardRepositoryProvider.future);
  
  TopMoversResponse movers = TopMoversResponse(timeFrame: timeFrame, gainers: [], losers: []);
  try {
    movers = await repository.getTopMovers(resolvedUserId, timeFrame: timeFrame);
  } catch (e) {
    AppLogger.warning('Failed to get top movers from analysis service', error: e);
  }
  
  yield movers;

  _attachDashboardStreaming(ref, resolvedUserId);
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

  PerformanceResponse performance;
  final sw = Stopwatch()..start();
  try {
    performance = await repository.getPerformance(userId, timeFrame: timeFrame);
  } catch (e) {
    AppLogger.warning(
      'Failed to get performance from analysis service. Trying fallback to portfolio service...',
      error: e,
    );
    try {
      final rawData = await _loadPortfolioSummaryFallback(ref);
      performance = _performanceFromPortfolioRaw(rawData, timeFrame);
    } catch (fallbackError) {
      sw.stop();
      ProductTelemetry.instance.widgetTiming(
        widget: 'dashboard_performance',
        durationMs: sw.elapsedMilliseconds,
        operation: 'fetch_error',
        technicalArea: 'dashboard',
      );
      ProductTelemetry.instance.clientError(errorType: 'dashboard_performance');
      AppLogger.error('Dashboard history fallback also failed', error: fallbackError);
      rethrow;
    }
  }
  sw.stop();
  ProductTelemetry.instance.widgetTiming(
    widget: 'dashboard_performance',
    durationMs: sw.elapsedMilliseconds,
    operation: 'fetch',
    technicalArea: 'dashboard',
  );
  if (performance.chartData.isEmpty) {
    ProductTelemetry.instance.emptyState('dashboard_performance_empty');
  }

  yield performance;

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
  try {
    return await repository.getPortfolioOverviews(userId);
  } catch (e) {
    AppLogger.warning(
      'Failed to get portfolio overviews from analysis service. Trying fallback to portfolio service...',
      error: e,
    );
    try {
      final rawData = await _loadPortfolioSummaryFallback(ref);
      return _portfolioOverviewsFromPortfolioRaw(rawData);
    } catch (fallbackError) {
      AppLogger.error(
        'Dashboard portfolio overviews fallback also failed',
        error: fallbackError,
      );
      rethrow;
    }
  }
}

// Legacy Future providers (REST-only fallbacks / refresh)
@riverpod
Future<AllocationResponse> dashboardAllocation(Ref ref, String userId) async {
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  try {
    return await repository.getAllocation(userId);
  } catch (e) {
    AppLogger.warning('Failed to get allocation from analysis service', error: e);
    return const AllocationResponse();
  }
}

@riverpod
Future<TopMoversResponse> topMovers(Ref ref, String userId, {String timeFrame = '1D'}) async {
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  try {
    return await repository.getTopMovers(userId, timeFrame: timeFrame);
  } catch (e) {
    AppLogger.warning('Failed to get top movers from analysis service', error: e);
    return TopMoversResponse(timeFrame: timeFrame, gainers: [], losers: []);
  }
}

@riverpod
Future<PerformanceResponse> dashboardPerformance(Ref ref, String userId, {String timeFrame = '1D'}) async {
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  try {
    return await repository.getPerformance(userId, timeFrame: timeFrame);
  } catch (e) {
    AppLogger.warning(
      'Failed to get performance from analysis service. Using fallback.',
      error: e,
    );
    final rawData = await _loadPortfolioSummaryFallback(ref);
    return _performanceFromPortfolioRaw(rawData, timeFrame);
  }
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
  try {
    return await repository.getRecentActivity(
      userId,
      page: page,
      size: size,
      sortBy: sortBy,
    );
  } catch (e) {
    AppLogger.warning('Failed to get recent activity from analysis service', error: e);
    return const RecentActivityResponse(items: [], totalItems: 0, totalPages: 0);
  }
}
