import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../internal/data/datasources/portfolio_overview_data_source.dart';
import '../internal/data/dtos/portfolio_summary_response_dto.dart';
import '../internal/domain/entities/trade_holding.dart';
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

  final merged = [
    for (var i = 0; i < realized.length; i++)
      _mergeViewModel(realized[i], summaries[i]),
  ];

  // Mail/demat books often leave am-portfolio overall/1D at null/0 (no cost).
  // Trade holdings enrich already computes todayProfitLoss + import-mark overall —
  // sum those onto the card when live gain is still flat.
  // Heal Live P&L and/or live Win Rate from Trade holdings enrich when flat.
  final needsTradeHeal = merged.any(
    (p) =>
        p.totalTrades > 0 &&
        (p.totalGainLoss == 0 || (p.winRate ?? 0) == 0),
  );
  if (!needsTradeHeal) return merged;

  try {
    return await Future.wait<TradePortfolioViewModel>(
      merged.map((portfolio) async {
        if (portfolio.totalTrades <= 0) return portfolio;
        if (portfolio.totalGainLoss != 0 && (portfolio.winRate ?? 0) != 0) {
          return portfolio;
        }
        try {
          final holdings = await ref
              .read(tradeHoldingsProvider(portfolio.id).future)
              .timeout(const Duration(seconds: 8));
          return _healLivePnlFromTradeHoldings(portfolio, holdings);
        } catch (_) {
          return portfolio;
        }
      }),
    ).timeout(
      const Duration(seconds: 12),
      onTimeout: () => merged,
    );
  } catch (_) {
    return merged;
  }
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

  // Closed win rate when there are closed trades; else live gainers / assets.
  // Never dilute closed W/L with (trades + assets) — that forced 0% on mail books.
  final closedCount = realized.winningTrades + realized.losingTrades;
  double? overallWinRate = realized.winRate;
  if (closedCount > 0) {
    overallWinRate = realized.winRate;
  } else if ((liveSummary.totalAssets ?? 0) > 0 &&
      liveSummary.gainersCount != null) {
    overallWinRate =
        liveSummary.gainersCount! / liveSummary.totalAssets!;
  }

  final hasOpenBook =
      realized.totalTrades > 0 || realized.openPositions > 0;

  // Do not let a flat overall 0 mask a non-zero 1D move (mail books often
  // persist totalGainLoss=0 while todayGainLoss is real).
  final liveGain = _firstNonZeroOrNull(
        liveSummary.totalGainLoss,
        liveSummary.todayChange,
      );
  final liveGainPct = _firstNonZeroOrNull(
        liveSummary.totalGainLossPercentage,
        liveSummary.todayChangePercentage,
      );

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

/// First non-zero wins; else first non-null (may be 0); else null.
double? _firstNonZeroOrNull(double? primary, double? fallback) {
  if (primary != null && primary != 0) return primary;
  if (fallback != null && fallback != 0) return fallback;
  return primary ?? fallback;
}

/// Sum Trade holdings enrich metrics onto the discovery card Live P&L / Win %.
TradePortfolioViewModel _healLivePnlFromTradeHoldings(
  TradePortfolioViewModel card,
  TradeHoldings holdings,
) {
  var daySum = 0.0;
  var overallSum = 0.0;
  var hasDay = false;
  var hasOverall = false;
  var scored = 0;
  var winners = 0;

  for (final trade in holdings.content) {
    final metrics = trade.metrics;
    if (metrics == null) continue;
    final day = metrics.todayProfitLoss;
    if (day != null) {
      hasDay = true;
      daySum += day;
    }
    final overall = metrics.profitLoss;
    if (overall != null) {
      hasOverall = true;
      overallSum += overall;
    }
    final signal = overall ?? day;
    if (signal != null) {
      scored++;
      if (signal > 0) winners++;
    }
  }

  final live = hasOverall
      ? overallSum
      : (hasDay ? daySum : null);
  final liveWinRate = scored > 0 ? winners / scored : null;

  final value = card.totalValue;
  final pct = live != null && value > 0
      ? (live / value) * 100
      : null;

  return card.copyWith(
    totalGainLoss: card.totalGainLoss == 0 && live != null
        ? live
        : null,
    totalGainLossPercentage: card.totalGainLoss == 0 && pct != null
        ? pct
        : null,
    winRate: (card.winRate ?? 0) == 0 && liveWinRate != null
        ? liveWinRate
        : null,
  );
}
