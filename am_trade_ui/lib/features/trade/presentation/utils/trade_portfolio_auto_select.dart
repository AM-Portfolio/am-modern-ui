import '../models/trade_portfolio_view_model.dart';

/// Picks which trade portfolio the UI should switch to after a list refresh.
///
/// Used after doc-parser / Kafka import creates a new trade portfolio while the
/// user is still stuck on an older empty selection.
TradePortfolioViewModel? resolveTradePortfolioAutoSelect({
  required List<TradePortfolioViewModel> portfolios,
  required Set<String>? knownIds,
  required String? currentPortfolioId,
}) {
  if (portfolios.isEmpty) return null;

  final currentIds = portfolios.map((p) => p.id).toSet();

  // 1) New portfolio appeared since last snapshot — prefer the most active one.
  if (knownIds != null) {
    final newIds = currentIds.difference(knownIds);
    if (newIds.isNotEmpty) {
      final newcomers =
          portfolios.where((p) => newIds.contains(p.id)).toList();
      newcomers.sort(_byActivityThenRecency);
      return newcomers.first;
    }
  }

  // 2) Current selection missing or empty while another portfolio has trades.
  final current = _findById(portfolios, currentPortfolioId);
  if (currentPortfolioId == null || current == null || _isEmpty(current)) {
    final ranked = [...portfolios]..sort(_byActivityThenRecency);
    final best = ranked.first;
    if (currentPortfolioId == null || current == null) {
      return best;
    }
    if (!_isEmpty(best) && best.id != currentPortfolioId) {
      return best;
    }
  }

  return null;
}

bool _isEmpty(TradePortfolioViewModel p) =>
    p.totalTrades <= 0 && p.openPositions <= 0 && p.holdingsCount <= 0;

TradePortfolioViewModel? _findById(
  List<TradePortfolioViewModel> portfolios,
  String? id,
) {
  if (id == null) return null;
  for (final p in portfolios) {
    if (p.id == id) return p;
  }
  return null;
}

int _byActivityThenRecency(
  TradePortfolioViewModel a,
  TradePortfolioViewModel b,
) {
  final activityCmp =
      (b.totalTrades + b.openPositions).compareTo(a.totalTrades + a.openPositions);
  if (activityCmp != 0) return activityCmp;
  final aTime = a.lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(0);
  final bTime = b.lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(0);
  return bTime.compareTo(aTime);
}
