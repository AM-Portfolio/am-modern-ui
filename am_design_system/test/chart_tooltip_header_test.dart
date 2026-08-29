import 'package:am_design_system/shared/widgets/charts/chart_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('combineChartTooltipHeader', () {
    test('keeps a single label', () {
      expect(combineChartTooltipHeader(['20 Aug']), '20 Aug');
      expect(combineChartTooltipHeader(['15:15']), '15:15');
    });

    test('joins mixed date and time once', () {
      expect(
        combineChartTooltipHeader(['26 Aug', '26 Aug', '15:15', '15:15']),
        '26 Aug · 15:15',
      );
    });

    test('picks the latest time when series clocks disagree', () {
      expect(combineChartTooltipHeader(['09:15', '15:15']), '15:15');
    });

    test('ignores blanks', () {
      expect(combineChartTooltipHeader([null, '', '26 Aug']), '26 Aug');
    });
  });
}
