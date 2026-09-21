import 'package:am_design_system/shared/widgets/charts/chart_series_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('timeframe axis formats', () {
    test('1D uses HH:mm', () {
      expect(axisDateFormatPattern('1D'), 'HH:mm');
    });
    test('1W uses weekday', () {
      expect(axisDateFormatPattern('1W'), 'E');
    });
    test('1M uses dd MMM', () {
      expect(axisDateFormatPattern('1M'), 'dd MMM');
    });
    test('1Y uses MMM yy', () {
      expect(axisDateFormatPattern('1Y'), 'MMM yy');
    });
    test('6M uses MMM yy', () {
      expect(axisDateFormatPattern('6M'), 'MMM yy');
    });
  });
}
