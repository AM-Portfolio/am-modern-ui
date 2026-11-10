import 'dart:async';

import 'package:am_dashboard_ui/data/repositories/dashboard_repository.dart';
import 'package:am_dashboard_ui/domain/models/activity_item.dart';
import 'package:am_dashboard_ui/domain/models/allocation_response.dart';
import 'package:am_dashboard_ui/domain/models/dashboard_summary.dart';
import 'package:am_dashboard_ui/domain/models/performance_response.dart';
import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_dashboard_ui/domain/models/portfolio_overview.dart';
import 'package:am_dashboard_ui/domain/models/recent_activity_response.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_provider.dart';
import 'package:am_dashboard_ui/presentation/layout/dashboard_widget_id.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_overlay_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_portfolio_scope.dart';
import 'package:am_news_ui/am_news_ui.dart';
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
  final filterKey = ref.watch(familyPortfolioFilterProvider);
  final persona = holdingsPersonaParam(filterKey);
  return client.get(
    config.api.portfolio.summaryResource,
    queryParams: {'persona': persona},
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
  if (visible.contains(DashboardWidgetId.portfolioList) ||
      visible.contains(DashboardWidgetId.accountsHub)) {
    ref.watch(accountsHubProvider(userId));
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
  if (visible.contains(DashboardWidgetId.news) &&
      ref.watch(newsUiSurfaceEnabledProvider(NewsUiSurface.dashboard))) {
    ref.watch(newsInsightProvider);
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

  final holdingsRaw =
      rawData['totalHoldings'] ?? rawData['totalAssets'] ?? rawData['holdingsCount'];
  final holdings = holdingsRaw is int
      ? holdingsRaw
      : holdingsRaw is num
          ? holdingsRaw.toInt()
          : int.tryParse('$holdingsRaw') ?? 0;

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
    totalHoldings: holdings,
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
  // Await the persona-watched provider — do not return a prior scope's hasValue
  // while Family filter is switching (that mixed You ₹ with household day%).
  final cached = ref.watch(portfolioSummaryFallbackProvider);
  if (cached.hasError) {
    ref.invalidate(portfolioSummaryFallbackProvider);
  }
  return ref.watch(portfolioSummaryFallbackProvider.future);
}

Future<DashboardSummary> _resolveDashboardSummary(
  Ref ref,
  DashboardRepository repository,
  String userId,
) async {
  final portfolioId = ref.watch(dashboardPortfolioScopeProvider);
  if (portfolioId != null &&
      portfolioId.isNotEmpty &&
      portfolioId != 'all') {
    final client = await ref.watch(portfolioApiClientProvider.future);
    final raw = await client
        .get<Map<String, dynamic>>(
          '/v1/portfolios/summary',
          queryParams: {'portfolioId': portfolioId},
          parser: (data) {
            if (data is Map) return Map<String, dynamic>.from(data);
            throw const FormatException('Portfolio summary was not an object');
          },
        )
        .timeout(const Duration(seconds: 20));
    return _dashboardSummaryFromPortfolioRaw(raw);
  }

  // Canonical headline wealth: portfolio summary with persona (hub residual).
  // Do not prefer unscoped analysis dashboard/summary for totals.
  try {
    final raw = await _loadPortfolioSummaryFallback(ref)
        .timeout(const Duration(seconds: 20));
    return _dashboardSummaryFromPortfolioRaw(raw);
  } catch (e) {
    AppLogger.warning(
      'Portfolio summary failed; trying analysis dashboard summary...',
      error: e,
    );
    try {
      return await repository
          .getSummary(userId)
          .timeout(const Duration(seconds: 20));
    } catch (finalError) {
      ref.invalidate(portfolioSummaryFallbackProvider);
      try {
        final raw = await ref
            .read(portfolioSummaryFallbackProvider.future)
            .timeout(const Duration(seconds: 25));
        return _dashboardSummaryFromPortfolioRaw(raw);
      } catch (_) {
        AppLogger.error(
          'Dashboard summary failed on portfolio and analysis paths',
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
  // Rebuild when Family persona changes so headline matches All yours / household.
  ref.watch(familyPortfolioFilterProvider);
  final repository = await ref.watch(dashboardRepositoryProvider.future);
  return _resolveDashboardSummary(ref, repository, userId);
}

@Riverpod(keepAlive: true)
Stream<DashboardSummary> dashboardStream(Ref ref, String userId) async* {
  final resolvedUserId = await _requireDashboardUserId(ref, userId);
  // Same persona dependency as dashboardSummary — avoid stale day% from prior scope.
  ref.watch(familyPortfolioFilterProvider);

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

/// Accounts hub (identity / demat / NPS / per-broker amounts).
final accountsHubProvider =
    FutureProvider.autoDispose.family<AccountsHub, String>((ref, userId) async {
  final link = ref.keepAlive();
  Timer? disposeTimer;
  ref.onCancel(() {
    disposeTimer?.cancel();
    disposeTimer = Timer(const Duration(minutes: 2), link.close);
  });
  ref.onResume(() => disposeTimer?.cancel());
  ref.onDispose(() => disposeTimer?.cancel());

  await _requireDashboardUserId(ref, userId);
  final client = await ref.watch(portfolioApiClientProvider.future);
  try {
    final raw = await client
        .get(
          '/v1/portfolios/accounts-hub',
          parser: (data) {
            if (data is Map) return Map<String, dynamic>.from(data);
            throw const FormatException('Accounts hub was not an object');
          },
        )
        .timeout(const Duration(seconds: 20));
    return AccountsHub.fromJson(raw);
  } catch (e, st) {
    AppLogger.warning('Accounts hub fetch failed', error: e, stackTrace: st);
    // Soft-fail so chart-row panels render empty / retry instead of spinning forever.
    return const AccountsHub();
  }
});

/// NPS scheme lines for a portfolio (Users NPS tab).
final npsSchemesProvider =
    FutureProvider.autoDispose.family<List<NpsSchemeLine>, String>(
        (ref, portfolioId) async {
  if (portfolioId.isEmpty) return const [];
  final client = await ref.watch(portfolioApiClientProvider.future);
  try {
    return await client
        .get(
          '/v1/portfolios/$portfolioId/nps/schemes',
          parser: (data) => (data as List)
              .whereType<Map>()
              .map((e) => NpsSchemeLine.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
        )
        .timeout(const Duration(seconds: 12));
  } catch (e, st) {
    AppLogger.warning('NPS schemes fetch failed', error: e, stackTrace: st);
    return const [];
  }
});

/// Soft family persona CRUD against portfolio-service.
Future<FamilyMemberRow> createFamilyMember({
  required ApiClient client,
  required String displayName,
  String? email,
}) async {
  final raw = await client.post(
    '/v1/portfolios/family-members',
    body: {
      'displayName': displayName,
      if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
    },
    parser: (data) {
      if (data is Map) return Map<String, dynamic>.from(data);
      throw const FormatException('Family member create was not an object');
    },
  );
  return FamilyMemberRow.fromJson(raw);
}

Future<FamilyMemberRow> updateFamilyMember({
  required ApiClient client,
  required String familyMemberId,
  String? displayName,
  String? email,
}) async {
  final body = <String, dynamic>{};
  if (displayName != null) body['displayName'] = displayName;
  if (email != null) body['email'] = email;
  final raw = await client.put(
    '/v1/portfolios/family-members/$familyMemberId',
    body: body,
    parser: (data) {
      if (data is Map) return Map<String, dynamic>.from(data);
      throw const FormatException('Family member update was not an object');
    },
  );
  return FamilyMemberRow.fromJson(raw);
}

Future<void> deleteFamilyMember({
  required ApiClient client,
  required String familyMemberId,
}) async {
  await client.delete(
    '/v1/portfolios/family-members/$familyMemberId',
    parser: (_) => null,
  );
}

List<PortfolioOverview> _portfolioOverviewsFromAccountsHub(AccountsHub hub) {
  final rows = hub.portfolios;
  if (rows.isEmpty) {
    return const [];
  }
  final cards = <PortfolioOverview>[];
  double investedSum = 0;
  double currentSum = 0;
  for (final row in rows) {
    final current = row.current ?? 0;
    final invested = row.invested ?? (current - (row.returnAbs ?? 0));
    final ret = row.returnAbs ?? (current - invested);
    final pct = row.returnPct ??
        (invested > 0 ? (ret / invested) * 100.0 : 0.0);
    investedSum += invested;
    currentSum += current;
    cards.add(
      PortfolioOverview(
        type: (row.displayName != null && row.displayName!.trim().isNotEmpty)
            ? row.displayName!.trim()
            : (row.brokerType ?? 'Portfolio'),
        totalValue: current,
        totalReturn: ret,
        returnPercentage: pct,
        dayChange: 0,
        dayChangePercentage: 0,
        portfolioCount: 1,
      ),
    );
  }
  final consRet = currentSum - investedSum;
  final consPct = investedSum > 0 ? (consRet / investedSum) * 100.0 : 0.0;
  cards.add(
    PortfolioOverview(
      type: 'CONSOLIDATED',
      totalValue: currentSum,
      totalReturn: consRet,
      returnPercentage: consPct,
      dayChange: 0,
      dayChangePercentage: 0,
      portfolioCount: rows.length,
    ),
  );
  return cards;
}

@riverpod
Future<List<PortfolioOverview>> portfolioOverviews(Ref ref, String userId) async {
  try {
    final hub = await ref.watch(accountsHubProvider(userId).future);
    final fromHub = _portfolioOverviewsFromAccountsHub(hub);
    if (fromHub.isNotEmpty) {
      return fromHub;
    }
  } catch (e) {
    AppLogger.warning(
      'Accounts hub unavailable for portfolio list; falling back',
      error: e,
    );
  }
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
