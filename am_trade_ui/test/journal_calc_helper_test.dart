import 'package:am_trade_ui/features/trade/presentation/journal/utils/journal_calc_helper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JournalCalcHelper', () {
    test('plannedRRRatio is reward/risk', () {
      final rr = JournalCalcHelper.plannedRRRatio(
        entry: 100,
        stop: 90,
        target: 130,
      );
      expect(rr, closeTo(3.0, 0.001));
    });

    test('actualPnl long and short', () {
      final longPnl = JournalCalcHelper.actualPnl(
        entryPrice: 100,
        exitPrice: 110,
        quantity: 10,
        tradeDirection: 'LONG',
      );
      final shortPnl = JournalCalcHelper.actualPnl(
        entryPrice: 100,
        exitPrice: 90,
        quantity: 10,
        tradeDirection: 'SHORT',
      );
      expect(longPnl, 100);
      expect(shortPnl, 100);
    });

    test('actualRMultiple divides by planned risk', () {
      final r = JournalCalcHelper.actualRMultiple(pnl: 200, plannedRisk: 100);
      expect(r, 2);
    });
  });
}
