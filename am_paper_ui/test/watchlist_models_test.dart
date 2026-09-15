import 'package:am_paper_ui/data/watchlist_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WatchlistStock copyWith updates quote fields', () {
    const base = WatchlistStock(
      symbol: 'RELIANCE',
      name: 'Reliance Industries',
      exchange: 'NSE',
      ltp: 0,
      change: 0,
      changePercent: 0,
    );
    final next = base.copyWith(ltp: 2500.5, change: 12.5, changePercent: 0.5);
    expect(next.symbol, 'RELIANCE');
    expect(next.ltp, 2500.5);
    expect(next.isPositive, isTrue);
  });
}
