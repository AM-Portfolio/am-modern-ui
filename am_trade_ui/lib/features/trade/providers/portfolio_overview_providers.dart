import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../internal/data/datasources/portfolio_overview_data_source.dart';
import '../internal/data/dtos/portfolio_summary_response_dto.dart';
import '../internal/domain/entities/trade_portfolio.dart';
import '../presentation/models/trade_portfolio_view_model.dart';
import 'portfolio_bridge_providers.dart';
import 'trade_internal_providers.dart';

export 'portfolio_bridge_providers.dart';

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
      await ref.watch(portfolioOverviewDataSourceProvider.future);

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
  // Step 1: Realized trade portfolios (required). Timeout so the page cannot
  // sit on skeletons forever if the trade API hangs.
  final TradePortfolioList tradePortfolioList;
  try {
    tradePortfolioList = await ref
        .watch(tradePortfoliosProvider.future)
        .timeout(const Duration(seconds: 20));
  } on TimeoutException {
    throw Exception('Timed out loading trade portfolios');
  }

  if (tradePortfolioList.portfolios.isEmpty) return [];

  final realized = tradePortfolioList.portfolios
      .map(TradePortfolioViewModel.fromEntity)
      .toList();

  // Step 2: Live am-portfolio summaries — fail open, never block the landing.
  // Call the data source directly (with timeouts) instead of watching
  // portfolioLiveSummaryProvider.future per id, which can leave this provider
  // in AsyncLoading indefinitely when any child hangs.
  PortfolioOverviewDataSource? dataSource;
  try {
    dataSource = await ref
        .watch(portfolioOverviewDataSourceProvider.future)
        .timeout(const Duration(seconds: 8));
  } catch (_) {
    return realized;
  }

  // Cap enrichment wait so Portfolios never sits behind slow am-portfolio calls.
  List<PortfolioSummaryResponseDto?> summaries;
  try {
    summaries = await Future.wait<PortfolioSummaryResponseDto?>(
      tradePortfolioList.portfolios.map((portfolio) async {
        try {
          return await dataSource!
              .getPortfolioSummary(portfolio.id)
              .timeout(const Duration(seconds: 4));
        } catch (_) {
          return null;
        }
      }),
    ).timeout(
      const Duration(seconds: 6),
      onTimeout: () => List<PortfolioSummaryResponseDto?>.filled(
        realized.length,
        null,
      ),
    );
  } catch (_) {
    return realized;
  }

  return [
    for (var i = 0; i < realized.length; i++)
      _mergeViewModel(realized[i], summaries[i]),
  ];
});

// ============================================================================
// Merge Logic (pure function — no side effects, easy to unit test)
// ============================================================================

/// Merges a realized TradePortfolioViewModel with an optional live summary.
///
/// **Rules:**
/// - `totalValue`: positive live value wins; a live **0** must not clobber a
///    positive trade ledger value when the book still has trades/open positions
///    (unknown-cost demat books often get a zero am-portfolio overlay).
/// - `totalGainLoss` / `%`: same positive-prefer rule.
/// - `netProfitLoss`: ALWAYS kept from trade (realized).
/// - `winRate`: (winningTrades + gainersCount) / (totalTrades + totalAssets)
///
/// When `liveSummary` is null, the realized-only view model is returned unchanged.
TradePortfolioViewModel _mergeViewModel(
  TradePortfolioViewModel realized,
  PortfolioSummaryResponseDto? liveSummary,
) {
  if (liveSummary == null) {
    return realized;
  }

  final int totalWinning =
      realized.winningTrades + (liveSummary.gainersCount ?? 0);
  final int totalItems =
      realized.totalTrades + (liveSummary.totalAssets ?? 0);

  double? overallWinRate = realized.winRate;
  if (totalItems > 0) {
    overallWinRate = totalWinning / totalItems;
  }

  final hasOpenBook =
      realized.totalTrades > 0 || realized.openPositions > 0;

  final liveGain = liveSummary.totalGainLoss ?? liveSummary.todayChange;
  final liveGainPct = liveSummary.totalGainLossPercentage ??
      liveSummary.todayChangePercentage;

  return realized.copyWith(
    totalValue: _preferLiveMetric(
      live: liveSummary.totalValue,
      realized: realized.totalValue,
      hasOpenBook: hasOpenBook,
    ),
    totalGainLoss: _preferLiveMetric(
      live: liveGain,
      realized: realized.totalGainLoss,
      hasOpenBook: hasOpenBook,
    ),
    totalGainLossPercentage: _preferLiveMetric(
      live: liveGainPct,
      realized: realized.totalGainLossPercentage,
      hasOpenBook: hasOpenBook,
    ),
    winRate: overallWinRate,
  );
}

/// Prefer non-null live metrics (including losses). Only fall back to realized
/// when live is missing or a flat 0 while realized still has a signal.
double _preferLiveMetric({
  required double? live,
  required double realized,
  required bool hasOpenBook,
}) {
  if (live == null) return realized;
  if (live != 0) return live;
  if (hasOpenBook && realized != 0) return realized;
  return live;
}
