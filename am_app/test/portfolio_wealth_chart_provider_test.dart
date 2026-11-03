import 'package:am_app/features/chart/portfolio_wealth_chart_provider.dart';
import 'package:am_dashboard_ui/domain/models/overlay_chart_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const dhanLower = 'c46f3f77-1e7c-4850-9e78-ecb6b568485f';
  const dhanUpper = 'C46F3F77-1E7C-4850-9E78-ECB6B568485F';

  List<OverlayPoint> pts(List<double> values) => [
        for (var i = 0; i < values.length; i++)
          OverlayPoint(
            xLabel: '2026-10-${(i + 1).toString().padLeft(2, '0')}',
            value: values[i],
          ),
      ];

  test('encodePortfolioSymbol lowercases uuid', () {
    expect(
      PortfolioWealthHistoricalProvider.encodePortfolioSymbol(
        dhanUpper,
        name: 'Dhan',
      ),
      'PORTFOLIO:$dhanLower|Dhan',
    );
  });

  test('resolveOverlayPoints matches id case-insensitively', () {
    final history = PortfolioOverlayHistory(
      aggregate: const [],
      portfolios: const [
        OverlayPortfolioRef(id: dhanLower, label: 'Dhan'),
      ],
      byPortfolioId: {
        dhanLower: pts([100, 110, 120]),
      },
    );

    final resolved = PortfolioWealthHistoricalProvider.resolveOverlayPoints(
      history,
      portfolioId: dhanUpper,
    );
    expect(resolved.map((p) => p.value), [100, 110, 120]);
  });

  test('barsFromHistoryRows matches overview single-book extraction', () {
    final raw = [
      {
        'snapshotDate': '2026-10-01',
        'totalUserWealth': 999.0,
        'portfolios': [
          {
            'portfolioId': dhanLower,
            'portfolioName': 'Dhan',
            'close': 2500000.0,
          },
          {
            'portfolioId': 'other-id',
            'portfolioName': 'Zerodha',
            'close': 100.0,
          },
        ],
      },
      {
        'snapshotDate': '2026-10-02',
        'portfolios': [
          {
            'portfolioId': dhanUpper, // different casing
            'close': 2510000.0,
          },
        ],
      },
    ];

    final bars = PortfolioWealthHistoricalProvider.barsFromHistoryRows(
      raw,
      portfolioId: dhanUpper,
    );
    expect(bars, hasLength(2));
    expect(bars[0].close, 2500000.0);
    expect(bars[1].close, 2510000.0);
  });

  test('barsFromHistoryRows uses portfolios.first when id missing in row', () {
    final raw = [
      {
        'snapshotDate': '2026-10-01',
        'portfolios': [
          {'portfolioId': dhanLower, 'close': 42.0},
        ],
      },
    ];
    final bars = PortfolioWealthHistoricalProvider.barsFromHistoryRows(
      raw,
      portfolioId: 'not-found-id',
    );
    expect(bars.single.close, 42.0);
  });

  test('resolveOverlayPoints falls back to aggregate', () {
    final history = PortfolioOverlayHistory(
      aggregate: pts([10, 20]),
      portfolios: const [],
      byPortfolioId: const {},
    );

    final resolved = PortfolioWealthHistoricalProvider.resolveOverlayPoints(
      history,
      portfolioId: dhanLower,
    );
    expect(resolved.map((p) => p.value), [10, 20]);
  });
}
