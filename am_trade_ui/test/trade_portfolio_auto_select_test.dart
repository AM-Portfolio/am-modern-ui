import 'package:flutter_test/flutter_test.dart';
import 'package:am_trade_ui/features/trade/presentation/models/trade_portfolio_view_model.dart';
import 'package:am_trade_ui/features/trade/presentation/utils/trade_portfolio_auto_select.dart';

void main() {
  TradePortfolioViewModel portfolio({
    required String id,
    int totalTrades = 0,
    int openPositions = 0,
    int holdingsCount = 0,
    DateTime? lastUpdated,
  }) {
    return TradePortfolioViewModel(
      id: id,
      name: id,
      totalTrades: totalTrades,
      openPositions: openPositions,
      holdingsCount: holdingsCount,
      lastUpdated: lastUpdated,
    );
  }

  test('selects newly appeared portfolio over known empty selection', () {
    final empty = portfolio(id: 'old-empty');
    final imported = portfolio(
      id: 'new-import',
      totalTrades: 174,
      lastUpdated: DateTime(2026, 9, 13),
    );

    final selected = resolveTradePortfolioAutoSelect(
      portfolios: [empty, imported],
      knownIds: {'old-empty'},
      currentPortfolioId: 'old-empty',
    );

    expect(selected?.id, 'new-import');
  });

  test('switches away from empty selection when list already has active portfolio',
      () {
    final empty = portfolio(id: 'old-empty');
    final imported = portfolio(id: 'imported', totalTrades: 174);

    final selected = resolveTradePortfolioAutoSelect(
      portfolios: [empty, imported],
      knownIds: null,
      currentPortfolioId: 'old-empty',
    );

    expect(selected?.id, 'imported');
  });

  test('defaults to most active portfolio when nothing selected', () {
    final a = portfolio(id: 'a', totalTrades: 2);
    final b = portfolio(id: 'b', totalTrades: 50);

    final selected = resolveTradePortfolioAutoSelect(
      portfolios: [a, b],
      knownIds: null,
      currentPortfolioId: null,
    );

    expect(selected?.id, 'b');
  });

  test('keeps current non-empty selection', () {
    final current = portfolio(id: 'current', totalTrades: 10);
    final other = portfolio(id: 'other', totalTrades: 50);

    final selected = resolveTradePortfolioAutoSelect(
      portfolios: [current, other],
      knownIds: {'current', 'other'},
      currentPortfolioId: 'current',
    );

    expect(selected, isNull);
  });
}
