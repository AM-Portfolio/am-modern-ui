import 'package:flutter_test/flutter_test.dart';
import 'package:am_market_ui/features/institutional_flows/domain/fii_dii_activity_models.dart';
import 'package:am_market_ui/features/market_analysis/internal/domain/models/institutional_flow_series.dart';

void main() {
  group('aggregateFlowWeeks', () {
    test('groups Mon–Fri sessions into one week', () {
      final byDay = <DateTime, FlowDayNets>{
        DateTime(2026, 9, 14): FlowDayNets(
          day: DateTime(2026, 9, 14),
          fiiCash: 100,
        ),
        DateTime(2026, 9, 15): FlowDayNets(
          day: DateTime(2026, 9, 15),
          fiiCash: 50,
        ),
        DateTime(2026, 9, 21): FlowDayNets(
          day: DateTime(2026, 9, 21),
          fiiCash: 10,
        ),
      };
      final weeks = aggregateFlowWeeks(byDay);
      expect(weeks.length, 2);
      final first = weeks[DateTime(2026, 9, 14)]!;
      expect(first.fiiCash, 150);
    });
  });

  group('aggregateFlowYears', () {
    test('sums months into year', () {
      final months = <DateTime, FlowDayNets>{
        DateTime(2025, 1): FlowDayNets(
          day: DateTime(2025, 1),
          fiiCash: 10,
          diiCash: 5,
        ),
        DateTime(2025, 6): FlowDayNets(
          day: DateTime(2025, 6),
          fiiCash: 20,
        ),
        DateTime(2026, 1): FlowDayNets(
          day: DateTime(2026, 1),
          fiiCash: 1,
        ),
      };
      final years = aggregateFlowYears(months);
      expect(years.length, 2);
      expect(years[DateTime(2025)]!.fiiCash, 30);
      expect(years[DateTime(2025)]!.diiCash, 5);
    });
  });

  group('barRatioFor', () {
    test('clamps and signs', () {
      expect(barRatioFor(50, 100), 0.5);
      expect(barRatioFor(-50, 100), -0.5);
      expect(barRatioFor(0, 0), 0);
      expect(barRatioFor(200, 100), 1);
    });
  });

  group('nifty join', () {
    test('missing day does not throw', () {
      final point = niftyForPeriod(
        periodStart: DateTime(2026, 9, 18),
        period: FiiDiiPeriod.daily,
        closes: const {},
        sessionsInPeriod: [DateTime(2026, 9, 18)],
      );
      expect(point, isNull);
    });

    test('parses history closes', () {
      final closes = niftyClosesFromHistory([
        {'time': '2026-09-18', 'close': 23346.4},
        {'time': '2026-09-17', 'close': 23200.0},
      ]);
      expect(closes[DateTime(2026, 9, 18)], 23346.4);
      final n = niftyForPeriod(
        periodStart: DateTime(2026, 9, 18),
        period: FiiDiiPeriod.daily,
        closes: closes,
        sessionsInPeriod: [DateTime(2026, 9, 18)],
      );
      expect(n, isNotNull);
      expect(n!.close, 23346.4);
      expect(n.change, closeTo(146.4, 0.01));
    });
  });

  group('buildActivityRows', () {
    test('maps segment amounts', () {
      final buckets = [
        FiiDiiPeriodBucket(
          periodStart: DateTime(2026, 9, 18),
          nets: FlowDayNets(
            day: DateTime(2026, 9, 18),
            fiiCash: 100,
            diiCash: -50,
          ),
          dateLabel: '18 Sep',
        ),
        FiiDiiPeriodBucket(
          periodStart: DateTime(2026, 9, 17),
          nets: FlowDayNets(
            day: DateTime(2026, 9, 17),
            fiiCash: -200,
          ),
          dateLabel: '17 Sep',
        ),
      ];
      final rows = buildActivityRows(
        buckets: buckets,
        segment: FiiDiiSegment.fiiCash,
      );
      expect(rows.length, 2);
      expect(rows.first.amountCr, 100);
      expect(rows.first.barRatio, 0.5);
      expect(rows.last.barRatio, -1);
    });
  });
}
