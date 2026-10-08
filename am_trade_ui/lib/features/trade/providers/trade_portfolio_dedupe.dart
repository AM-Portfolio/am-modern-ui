import '../presentation/models/trade_portfolio_view_model.dart';

/// Collapses trade-portfolio list clones for overview / stream providers.
///
/// Order is intentional and must stay stable:
/// 1. Same non-empty id → keep the first occurrence.
/// 2. Same non-empty display name → keep the first occurrence.
///
/// Name collapse is required for Demo/Upstox clone cards that share a label
/// with different UUIDs. Portfolios with distinct names are always kept.
/// Empty-name rows are never dropped by the name pass.
List<TradePortfolioViewModel> dedupeTradePortfolios(
  Iterable<TradePortfolioViewModel> input,
) {
  final byId = <String>{};
  final ordered = <TradePortfolioViewModel>[];
  for (final p in input) {
    final id = p.id.trim().toLowerCase();
    if (id.isNotEmpty && !byId.add(id)) {
      continue;
    }
    ordered.add(p);
  }

  final byName = <String>{};
  final out = <TradePortfolioViewModel>[];
  for (final p in ordered) {
    final nameKey = p.name.trim().toLowerCase();
    if (nameKey.isNotEmpty && !byName.add(nameKey)) {
      continue;
    }
    out.add(p);
  }
  return out;
}
