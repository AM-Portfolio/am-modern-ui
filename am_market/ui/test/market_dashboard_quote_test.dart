import 'package:flutter_test/flutter_test.dart';
import 'package:am_market_ui/shared/widgets/constituents_table.dart';

void main() {
  group('resolveWatchQuote', () {
    test('uses batch fields when live is null', () {
      final q = resolveWatchQuote(
        batchLtp: 10,
        batchChange: 1,
        batchPChange: 2,
        live: null,
      );
      expect(q.ltp, 10);
      expect(q.change, 1);
      expect(q.pChange, 2);
    });

    test('prefers live quote when present', () {
      final q = resolveWatchQuote(
        batchLtp: 10,
        batchChange: 1,
        batchPChange: 2,
        live: {
          'lastPrice': 22.5,
          'change': -0.5,
          'changePercent': -2.2,
        },
      );
      expect(q.ltp, 22.5);
      expect(q.change, -0.5);
      expect(q.pChange, -2.2);
    });

    test('keeps batch LTP when live lastPrice is zero', () {
      final q = resolveWatchQuote(
        batchLtp: 50,
        batchChange: 3,
        batchPChange: 6,
        live: {'lastPrice': 0, 'change': 9, 'changePercent': 1},
      );
      expect(q.ltp, 50);
      expect(q.change, 9);
      expect(q.pChange, 1);
    });
  });
}
