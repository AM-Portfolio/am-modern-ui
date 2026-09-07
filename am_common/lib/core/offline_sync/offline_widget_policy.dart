import 'offline_domain.dart';

/// Granular UI/data surfaces that can opt into offline cache or hide offline.
/// Host enables them via [OfflineSyncConfig.widgets] — one place, not per-file flags.
enum OfflineWidgetId {
  portfolioHoldings,
  portfolioSummary,
  portfolioList,
  tradeList,
  tradeCalendar,
  tradeMetrics,
  dashboardSummary,
  dashboardPortfolios,
  dashboardAllocation,
  dashboardPerformanceChart,
  dashboardTopMovers,
  dashboardRecentActivity,
  aiSessionList,
  aiSessionDetail,
}

class OfflineWidgetPolicy {
  const OfflineWidgetPolicy({
    required this.id,
    required this.domain,
    this.cacheOnFailure = true,
    this.hideWhenOffline = false,
    this.allowQueuedWrites = false,
  });

  final OfflineWidgetId id;
  final OfflineDomain domain;

  /// On network failure, repositories may return local cache instead of throwing.
  final bool cacheOnFailure;

  /// UI should not show this widget while offline (e.g. top movers).
  final bool hideWhenOffline;

  /// Mutations for this surface may go through the outbox when writes flag is on.
  final bool allowQueuedWrites;
}

/// Default AM app widget matrix. Host can replace or merge in [OfflineSyncConfig].
class OfflineWidgetCatalog {
  OfflineWidgetCatalog._();

  static const List<OfflineWidgetPolicy> amAppDefaults = [
    OfflineWidgetPolicy(
      id: OfflineWidgetId.portfolioHoldings,
      domain: OfflineDomain.portfolio,
    ),
    OfflineWidgetPolicy(
      id: OfflineWidgetId.portfolioSummary,
      domain: OfflineDomain.portfolio,
    ),
    OfflineWidgetPolicy(
      id: OfflineWidgetId.portfolioList,
      domain: OfflineDomain.portfolio,
    ),
    OfflineWidgetPolicy(
      id: OfflineWidgetId.tradeList,
      domain: OfflineDomain.trades,
      allowQueuedWrites: true,
    ),
    OfflineWidgetPolicy(
      id: OfflineWidgetId.tradeCalendar,
      domain: OfflineDomain.trades,
    ),
    OfflineWidgetPolicy(
      id: OfflineWidgetId.tradeMetrics,
      domain: OfflineDomain.trades,
    ),
    OfflineWidgetPolicy(
      id: OfflineWidgetId.dashboardSummary,
      domain: OfflineDomain.dashboard,
    ),
    OfflineWidgetPolicy(
      id: OfflineWidgetId.dashboardPortfolios,
      domain: OfflineDomain.dashboard,
    ),
    OfflineWidgetPolicy(
      id: OfflineWidgetId.dashboardAllocation,
      domain: OfflineDomain.dashboard,
    ),
    OfflineWidgetPolicy(
      id: OfflineWidgetId.dashboardPerformanceChart,
      domain: OfflineDomain.dashboard,
    ),
    OfflineWidgetPolicy(
      id: OfflineWidgetId.dashboardTopMovers,
      domain: OfflineDomain.dashboard,
      cacheOnFailure: false,
      hideWhenOffline: true,
    ),
    OfflineWidgetPolicy(
      id: OfflineWidgetId.dashboardRecentActivity,
      domain: OfflineDomain.dashboard,
    ),
    OfflineWidgetPolicy(
      id: OfflineWidgetId.aiSessionList,
      domain: OfflineDomain.aiChat,
    ),
    OfflineWidgetPolicy(
      id: OfflineWidgetId.aiSessionDetail,
      domain: OfflineDomain.aiChat,
      allowQueuedWrites: true,
    ),
  ];

  static Map<OfflineWidgetId, OfflineWidgetPolicy> asMap(
    Iterable<OfflineWidgetPolicy> policies,
  ) {
    return {for (final p in policies) p.id: p};
  }
}
