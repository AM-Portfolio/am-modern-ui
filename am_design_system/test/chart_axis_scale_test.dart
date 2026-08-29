import 'package:am_design_system/shared/widgets/charts/chart_axis_scale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartAxisScale', () {
    test('lakhs small range is not cropped to 9.28L–9.38L', () {
      final axis = ChartAxisScale.fromRange(928000, 938000);
      expect(axis.unit, ChartAxisUnit.lakh);
      expect(axis.minY, lessThan(928000));
      expect(axis.maxY, greaterThan(938000));
      expect(axis.maxY - axis.minY, greaterThanOrEqualTo(933000 * 0.08));
      expect(axis.minY, greaterThanOrEqualTo(0));
      expect(axis.format(axis.minY), contains('L'));
      expect(axis.format(900000), '9L');
    });

    test('thousands use K labels', () {
      final axis = ChartAxisScale.fromRange(11800, 12400);
      expect(axis.unit, ChartAxisUnit.thousand);
      expect(axis.format(12000), '12K');
      expect(axis.minY, lessThan(11800));
      expect(axis.maxY, greaterThan(12400));
    });

    test('crores keep a band and do not start at 0', () {
      final axis = ChartAxisScale.fromRange(63000000, 63200000);
      expect(axis.unit, ChartAxisUnit.crore);
      expect(axis.minY, greaterThan(0));
      expect(axis.minY, lessThan(63000000));
      expect(axis.maxY - axis.minY, greaterThanOrEqualTo(63100000 * 0.08));
      expect(axis.format(60000000), '6Cr');
    });

    test('flat values still get an 8% band', () {
      final axis = ChartAxisScale.fromValues([934000, 934000, 934000]);
      expect(axis.minY, lessThan(934000));
      expect(axis.maxY, greaterThan(934000));
      expect(axis.maxY - axis.minY, greaterThanOrEqualTo(934000 * 0.08));
    });

    test('small percent range still has several ticks', () {
      final axis = ChartAxisScale.fromValues([0, 0.2], minBandFraction: 0.2);
      expect(axis.ticks.length, greaterThanOrEqualTo(4));
      expect(axis.step, lessThan(axis.maxY - axis.minY));
    });

    test('compactRupee suffixes', () {
      expect(ChartAxisScale.compactRupee(850), '850');
      expect(ChartAxisScale.compactRupee(12500), '12.5K');
      expect(ChartAxisScale.compactRupee(928000), '9.28L');
      expect(ChartAxisScale.compactRupee(63100000), '6.31Cr');
    });
  });
}
