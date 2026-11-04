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

  test('portfolio toolbar hides intraday chips', () {
    expect(
      ChartTimeframe.phase1ForSymbol('NIFTY 50'),
      ChartTimeframe.phase1,
    );
    expect(
      ChartTimeframe.phase1ForSymbol(
        'PORTFOLIO:c46f3f77-1e7c-4850-9e78-ecb6b56b485f|Dhan Portfolio',
      ),
      ChartTimeframe.phase1Portfolio,
    );
    expect(
      ChartTimeframe.phase1Portfolio,
      isNot(contains(ChartTimeframe.m5)),
    );
    expect(
      ChartTimeframe.phase1Portfolio,
      isNot(contains(ChartTimeframe.m15)),
    );
    expect(
      ChartTimeframe.phase1Portfolio,
      isNot(contains(ChartTimeframe.h1)),
    );
    expect(
      ChartTimeframe.coerceForSymbol('PORTFOLIO:abc', ChartTimeframe.m5),
      ChartTimeframe.d1,
    );
    expect(
      ChartTimeframe.coerceForSymbol('RELIANCE', ChartTimeframe.m5),
      ChartTimeframe.m5,
    );
  });
}
