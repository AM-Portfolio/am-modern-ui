import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/core/di/network_providers.dart';

import '../internal/data/datasources/portfolio_overview_data_source.dart';
import '../internal/data/dtos/portfolio_summary_response_dto.dart';
import '../presentation/models/trade_portfolio_view_model.dart';
import 'trade_internal_providers.dart';

// ============================================================================
// Infrastructure (private — not for direct UI consumption)
// ============================================================================

/// Private provider that wires up the PortfolioOverviewDataSource.
///
/// Uses the existing shared ApiClient (so auth headers are automatically
/// forwarded) and the PortfolioApiConfig that is already in AppConfig.
final _portfolioOverviewDataSourceProvider =
    FutureProvider<PortfolioOverviewDataSource>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final appConfig = await ref.watch(appConfigProvider.future);

  return PortfolioOverviewDataSourceImpl(
    apiClient: apiClient,
    portfolioConfig: appConfig.api.portfolio,
  );
});

// ============================================================================
// Public Providers (for UI consumption)
// ============================================================================

/// Fetches the live Unrealized P&L summary for a single portfolio from
/// am-portfolio. Returns null if the portfolio has no data or if the request
/// fails — callers must handle null safely.
///
/// This is a FutureProvider.family keyed by portfolioId (the UUID that
/// am-portfolio uses as its document _id).
///
/// **Why family?** Each portfolio card needs an independent live summary.
/// Riverpod caches each (portfolioId) separately so we don't re-fetch
/// when the user scrolls.
final portfolioLiveSummaryProvider =
    FutureProvider.family<PortfolioSummaryResponseDto?, String>(
        (ref, portfolioId) async {
  if (portfolioId.isEmpty) return null;

  final dataSource =
      await ref.watch(_portfolioOverviewDataSourceProvider.future);

  // The data source itself never throws — it returns null on errors.
  return dataSource.getPortfolioSummary(portfolioId);
});

/// The enriched portfolio list — stitches together:
///   - Realized metrics (Win Rate, Net P&L) from am-trade-management
///   - Live Unrealized metrics (Portfolio Value, Live Gain/Loss) from am-portfolio
///
/// ## Data Flow
/// ```
/// am-trade-management  ──────────────────────────────────►  Realized: winRate, netProfitLoss
///                                                              (correct at 0 when no closed trades)
///
/// am-portfolio  ─────────────────────────────────────────►  Unrealized: totalValue, totalGainLoss
///                                                              (live, ticking every ~30s)
///                                          │
///                                          ▼
///                              enrichedTradePortfoliosProvider
///                                (merges both into TradePortfolioViewModel)
///                                          │
///                                          ▼
///                              TradePortfolioDiscoveryTemplate
/// ```
///
/// ## Failure Isolation
/// If am-portfolio is down, the Trade dashboard still renders fully using
/// only realized data. The Live Gain/Loss will show ₹0.00, but the card
/// will not crash, not show an error screen, and not block navigation.
///
/// This is enforced by the `catchError` on each `portfolioLiveSummaryProvider`
/// call and the null-safe `_mergeViewModel` function.
final enrichedTradePortfoliosProvider =
    FutureProvider<List<TradePortfolioViewModel>>((ref) async {
  // Step 1: Get the realized trade data (always required — if this fails,
  // the page already shows an error via its own AsyncValue handling)
  final tradePortfolioList = await ref.watch(tradePortfoliosProvider.future);

  if (tradePortfolioList.portfolios.isEmpty) return [];

  // Step 2: Concurrently fetch live summary for every portfolio.
  // We use Future.wait with individual catchErrors so one failure never
  // prevents other portfolios from showing live data.
  final summaryFutures = tradePortfolioList.portfolios.map((portfolio) {
    return ref
        .watch(portfolioLiveSummaryProvider(portfolio.id).future)
        .catchError((Object e) {
      // Fail open: treat network errors as "no live data available"
      return null as PortfolioSummaryResponseDto?;
    });
  });

  final summaries = await Future.wait(summaryFutures);

  // Step 3: Merge realized + unrealized into the final view models
  final enriched = <TradePortfolioViewModel>[];
  for (int i = 0; i < tradePortfolioList.portfolios.length; i++) {
    final tradePortfolio = tradePortfolioList.portfolios[i];
    final liveSummary = summaries[i]; // may be null

    enriched.add(_mergeViewModel(
      TradePortfolioViewModel.fromEntity(tradePortfolio),
      liveSummary,
    ));
  }

  return enriched;
});

// ============================================================================
// Merge Logic (pure function — no side effects, easy to unit test)
// ============================================================================

/// Merges a realized TradePortfolioViewModel with an optional live summary.
///
/// **Rules:**
/// - `totalValue`: live portfolio value wins over the stale trade value.
/// - `totalGainLoss`: live unrealized P&L wins (this is what shows on the card bottom).
/// - `totalGainLossPercentage`: live percentage wins.
/// - `netProfitLoss`: ALWAYS kept from trade. This is Realized P&L and must
///    never be overridden with the portfolio's unrealized figure.
/// - `winRate`: Calculated as (winningTrades + gainersCount) / (totalTrades + totalAssets)
///
/// When `liveSummary` is null (am-portfolio down or no data), the realized-only
/// view model is returned unchanged — the card degrades gracefully.
TradePortfolioViewModel _mergeViewModel(
  TradePortfolioViewModel realized,
  PortfolioSummaryResponseDto? liveSummary,
) {
  if (liveSummary == null) {
    // No live data — show what we have from the trade ledger
    return realized;
  }

  // Calculate overall win rate using both closed trades and live holdings
  final int totalWinning = realized.winningTrades + (liveSummary.gainersCount ?? 0);
  final int totalItems = realized.totalTrades + (liveSummary.totalAssets ?? 0);
  
  double? overallWinRate = realized.winRate; // Default to existing if no trades/holdings
  if (totalItems > 0) {
    overallWinRate = totalWinning / totalItems;
  }

  return realized.copyWith(
    // Live portfolio metrics override stale trade ledger values
    totalValue: liveSummary.totalValue ?? realized.totalValue,
    totalGainLoss: liveSummary.totalGainLoss ?? realized.totalGainLoss,
    totalGainLossPercentage:
        liveSummary.totalGainLossPercentage ?? realized.totalGainLossPercentage,
    // Overall win rate incorporates live gainers
    winRate: overallWinRate,
    // NOTE: netProfitLoss is intentionally NOT overridden here.
    // It remains as-is from the trade ledger (Realized metrics).
  );
}
