import 'package:am_chart_ui/src/providers/mock_providers.dart';
import 'package:am_chart_ui/src/timeframe/chart_timeframe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mock historical returns bars', () async {
    final p = MockHistoricalDataProvider();
    final bars = await p.getBars(symbol: 'NIFTY 50', timeframe: '1D');
    expect(bars.length, greaterThan(10));
    expect(p.isMock, isTrue);
  });

  test('timeframe from code', () {
    expect(ChartTimeframe.fromCode('5M'), ChartTimeframe.m5);
    expect(ChartTimeframe.fromCode('bogus'), ChartTimeframe.d1);
  });
}
