import 'package:am_trade_ui/features/trade/presentation/models/trade_portfolio_view_model.dart';
import 'package:am_trade_ui/features/trade/providers/trade_portfolio_dedupe.dart';
import 'package:flutter_test/flutter_test.dart';

TradePortfolioViewModel _p({
  required String id,
  required String name,
}) =>
    TradePortfolioViewModel(id: id, name: name);

void main() {
  test('keeps first when ids collide (case/whitespace insensitive)', () {
    final out = dedupeTradePortfolios([
      _p(id: 'AAA', name: 'Upstox'),
      _p(id: ' aaa ', name: 'Upstox Clone'),
    ]);
    expect(out, hasLength(1));
    expect(out.single.name, 'Upstox');
  });

  test('collapses Demo/Upstox same-name clones with different ids', () {
    final out = dedupeTradePortfolios([
      _p(id: 'real-uuid', name: 'Upstox'),
      _p(id: 'demo-uuid', name: 'Upstox'),
      _p(id: 'other', name: 'Demo Portfolio'),
    ]);
    expect(out.map((p) => p.id).toList(), ['real-uuid', 'other']);
  });

  test('keeps portfolios with distinct names', () {
    final out = dedupeTradePortfolios([
      _p(id: '1', name: 'Retirement'),
      _p(id: '2', name: 'Trading'),
    ]);
    expect(out, hasLength(2));
  });

  test('empty-name rows are not dropped by the name pass', () {
    final out = dedupeTradePortfolios([
      _p(id: '1', name: ''),
      _p(id: '2', name: '  '),
    ]);
    expect(out, hasLength(2));
  });
}
