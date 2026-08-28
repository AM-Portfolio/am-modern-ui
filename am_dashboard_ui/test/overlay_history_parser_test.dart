import 'package:am_dashboard_ui/domain/models/overlay_chart_models.dart';
import 'package:am_dashboard_ui/domain/models/overlay_history_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const zerodhaA = '065054d6-07af-445e-a795-755d872841c0';
  const zerodhaB = '1ce6f730-bb0d-4610-811f-fb02779b0d58';
  const groww = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee';

  List<Map<String, dynamic>> twoZerodhaDays() => [
        {
          'snapshotDate': '2026-08-20',
          'totalUserWealth': 100.0,
          'portfolios': [
            {
              'portfolioId': zerodhaA,
              'portfolioName': 'Zerodha',
              'brokerType': 'ZERODHA',
              'close': 60.0,
            },
            {
              'portfolioId': zerodhaB,
              'portfolioName': 'Zerodha',
              'brokerType': 'ZERODHA',
              'close': 40.0,
            },
          ],
        },
        {
          'snapshotDate': '2026-08-21',
          'totalUserWealth': 110.0,
          'portfolios': [
            {
              'portfolioId': zerodhaA,
              'portfolioName': 'Zerodha',
              'close': 66.0,
            },
          ],
        },
        {
          'snapshotDate': '2026-08-22',
          'totalUserWealth': 120.0,
          'portfolios': [
            {
              'portfolioId': zerodhaA,
              'portfolioName': 'Zerodha',
              'close': 70.0,
            },
            {
              'portfolioId': zerodhaB,
              'portfolioName': 'Zerodha',
              'close': 50.0,
            },
          ],
        },
      ];

  group('parsePortfolioOverlayHistory', () {
    test('two same-name portfolios become two series with unique labels', () {
      final history = parsePortfolioOverlayHistory(
        twoZerodhaDays(),
        isIntraday: false,
      );

      expect(history.portfolios.map((p) => p.id), [zerodhaA, zerodhaB]);
      expect(history.portfolios.map((p) => p.label).toSet().length, 2);
      expect(history.portfolios[0].label, startsWith('Zerodha · '));
      expect(history.portfolios[1].label, startsWith('Zerodha · '));
      expect(history.byPortfolioId[zerodhaA], hasLength(3));
      expect(history.byPortfolioId[zerodhaB], hasLength(3));
      expect(history.aggregate.map((p) => p.value), [100.0, 110.0, 120.0]);
    });

    test('carries forward last close when a day omits a portfolio', () {
      final history = parsePortfolioOverlayHistory(
        twoZerodhaDays(),
        isIntraday: false,
      );

      expect(
        history.byPortfolioId[zerodhaB]!.map((p) => p.value).toList(),
        [40.0, 40.0, 50.0],
      );
    });

    test('1D uses portfolios[].value', () {
      final history = parsePortfolioOverlayHistory(
        [
          {
            'timestamp': '09:15',
            'totalWealth': 100.0,
            'portfolios': [
              {'portfolioId': zerodhaA, 'portfolioName': 'Zerodha', 'value': 55.0},
            ],
          },
          {
            'timestamp': '09:20',
            'totalWealth': 101.0,
            'portfolios': [
              {'portfolioId': zerodhaA, 'portfolioName': 'Zerodha', 'value': 56.0},
            ],
          },
        ],
        isIntraday: true,
      );

      expect(
        history.byPortfolioId[zerodhaA]!.map((p) => p.value).toList(),
        [55.0, 56.0],
      );
    });

    test('does not use a UUID as the visible portfolio name', () {
      final history = parsePortfolioOverlayHistory(
        [
          {
            'snapshotDate': '2026-08-20',
            'totalUserWealth': 100.0,
            'portfolios': [
              {
                'portfolioId': zerodhaA,
                'portfolioName': '',
                'close': 100.0,
              },
            ],
          },
        ],
        isIntraday: false,
      );
      expect(history.portfolios.single.label, 'Portfolio');
      expect(history.portfolios.single.label.contains('-'), isFalse);
    });

    test('does not show userId when it is sent as the portfolio name', () {
      const userId = '39a1da0e-4424-4019-8960-aec84cb56e3e';
      final history = parsePortfolioOverlayHistory(
        [
          {
            'snapshotDate': '2026-08-20',
            'totalUserWealth': 100.0,
            'portfolios': [
              {
                'portfolioId': zerodhaA,
                'portfolioName': userId,
                'close': 100.0,
              },
            ],
          },
        ],
        isIntraday: false,
      );
      expect(history.portfolios.single.label, 'Portfolio');
      expect(history.portfolios.single.label, isNot(userId));
    });

    test('lists portfolios even when close is omitted', () {
      final history = parsePortfolioOverlayHistory(
        [
          {
            'snapshotDate': '2026-08-20',
            'totalUserWealth': 100.0,
            'portfolios': [
              {
                'portfolioId': zerodhaA,
                'portfolioName': 'Zerodha',
                'brokerType': 'ZERODHA',
              },
              {
                'portfolioId': zerodhaB,
                'portfolioName': 'Zerodha',
                'brokerType': 'ZERODHA',
              },
            ],
          },
        ],
        isIntraday: false,
      );

      expect(history.portfolios.map((p) => p.id), [zerodhaA, zerodhaB]);
    });
  });

  group('default overlay selection', () {
    test('defaults to Overall plus first two portfolios', () {
      expect(
        defaultOverlaySelectedIds([zerodhaA, zerodhaB, groww]),
        [OverlayChartIds.overall, zerodhaA, zerodhaB],
      );
    });

    test('one portfolio plus Overall and NIFTY 50', () {
      expect(
        defaultOverlaySelectedIds([zerodhaA]),
        [OverlayChartIds.overall, zerodhaA, OverlayChartIds.nifty50],
      );
    });

    test('untouched selection resets to default after history load', () {
      expect(
        mergeOverlaySelection(
          previous: const [OverlayChartIds.nifty50],
          availablePortfolioIds: [zerodhaA, zerodhaB],
          selectionTouched: false,
        ),
        [OverlayChartIds.overall, zerodhaA, zerodhaB],
      );
    });

    test('touched selection keeps user mix', () {
      expect(
        mergeOverlaySelection(
          previous: [groww, OverlayChartIds.sensex],
          availablePortfolioIds: [zerodhaA, zerodhaB, groww],
          selectionTouched: true,
        ),
        [groww, OverlayChartIds.sensex],
      );
    });

    test('default stays 3 even when more portfolios exist', () {
      final ids = [
        zerodhaA,
        zerodhaB,
        groww,
        'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'cccccccc-cccc-cccc-cccc-cccccccccccc',
      ];
      final selected = defaultOverlaySelectedIds(ids);
      expect(selected, [OverlayChartIds.overall, zerodhaA, zerodhaB]);
      expect(selected, hasLength(OverlayChartIds.defaultVisibleLines));
    });

    test('touched mix can grow past 3 up to 10', () {
      final portfolios = [
        for (var i = 0; i < 12; i++) 'pf-$i',
      ];
      final previous = [
        OverlayChartIds.overall,
        ...portfolios.take(9),
        OverlayChartIds.nifty50,
        OverlayChartIds.sensex,
      ];
      final kept = mergeOverlaySelection(
        previous: previous,
        availablePortfolioIds: portfolios,
        selectionTouched: true,
      );
      expect(kept, hasLength(OverlayChartIds.maxVisibleLines));
      expect(kept.contains(OverlayChartIds.sensex), isFalse);
    });
  });

  group('overlay axis labels', () {
    test('shortens daily dates and intraday times', () {
      expect(shortOverlayXLabel('2026-08-20'), '20 Aug');
      expect(shortOverlayXLabel('2026-08-26T09:15:00'), '26 Aug');
      expect(
        shortOverlayXLabel('2026-08-26T09:15:00', preferTime: true),
        '09:15',
      );
    });

    test('formats percent ticks with sign', () {
      expect(formatOverlayPercent(0), '0.0%');
      expect(formatOverlayPercent(-0.0), '0.0%');
      expect(formatOverlayPercent(1.24), '+1.2%');
      expect(formatOverlayPercent(-4.0), '-4%');
      expect(formatOverlayPercent(12.4), '+12%');
      expect(formatOverlayPercent(-0.56), '-0.56%');
      expect(formatOverlayAxisPercent(-0.5), '-0.5%');
      expect(formatOverlayAxisPercent(-1), '-1.0%');
      expect(formatOverlayAxisPercent(0), '0.0%');
    });
  });
}
