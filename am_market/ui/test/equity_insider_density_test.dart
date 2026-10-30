import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/equity_insider/presentation/pages/equity_insider_page.dart';
import 'package:am_market_ui/features/equity_insider/presentation/widgets/equity_insider_desktop_pair.dart';
import 'package:am_market_ui/features/equity_insider/providers/equity_insider_provider.dart';
import 'package:am_market_ui/features/watchlists/data/models/watchlist_model.dart';
import 'package:am_market_ui/features/watchlists/providers/watchlist_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ThemeData _theme() {
  return ThemeData.dark().copyWith(
    extensions: <ThemeExtension<dynamic>>[
      AppColorsTheme.dark,
      MarketThemeExtension.dark(),
    ],
  );
}

FundamentalRatiosResponse _ratios() {
  return FundamentalRatiosResponse(
    symbol: 'RELIANCE',
    companyName: 'RELIANCE INDUSTRIES LTD',
    currentPrice: 1209,
    dayChange: 7,
    dayChangePercent: 0.58,
    peRatio: 24.1,
    pbRatio: 2.2,
    roe: 9.1,
    roce: 11.4,
    roa: 4.2,
    operatingMarginPercent: 16.5,
    netProfitMarginPercent: 8.4,
    cfoPat: 1.1,
    currentRatio: 1.2,
    debtToEquity: 0.4,
    dividendYield: 0.5,
    evEbitda: 12.3,
  );
}

const _chartData = MultiSeriesChartData(
  series: {
    'RELIANCE': [
      MultiSeriesPoint(time: '2025-12-01', value: 1500),
      MultiSeriesPoint(time: '2026-02-23', value: 1428),
      MultiSeriesPoint(time: '2026-06-01', value: 1280),
    ],
  },
);

_overrides({List<dynamic>? shareholding}) {
  return [
    newsUiEnabledProvider.overrideWith((ref) => false),
    newsUiSurfaceEnabledProvider(NewsUiSurface.equityInsider)
        .overrideWith((ref) => false),
    fundamentalProfileProvider.overrideWith((ref, query) async => _ratios()),
    fundamentalUnifiedProvider.overrideWith((ref, query) async => _ratios()),
    fundamentalFinancialsProvider.overrideWith((ref, symbol) async => null),
    fundamentalShareholdingProvider.overrideWith(
      (ref, symbol) async => shareholding,
    ),
    fundamentalPeersProvider.overrideWith((ref, query) async => const []),
    equityStockChartDataProvider.overrideWith((ref, query) async => _chartData),
    watchlistCheckStatusProvider.overrideWith((ref, symbol) {
      return Future<List<WatchlistCheckStatus>>.value(
        const <WatchlistCheckStatus>[],
      );
    }),
  ];
}

Future<void> _pumpPage(
  WidgetTester tester, {
  required Size size,
  List<dynamic>? shareholding = const [],
}) async {
  final container = ProviderContainer(overrides: _overrides(shareholding: shareholding));
  addTearDown(container.dispose);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: _theme(),
        home: const EquityInsiderPage(initialSymbol: 'RELIANCE'),
      ),
    ),
  );
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    _drainLayoutExceptions(tester);
  }
}

void _drainLayoutExceptions(WidgetTester tester) {
  Object? error = tester.takeException();
  while (error != null) {
    error = tester.takeException();
  }
}

void main() {
  testWidgets('desktop pair copies left height onto the right', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: EquityInsiderDesktopPair(
              left: SizedBox(height: 320, child: ColoredBox(color: Colors.red)),
              right: ColoredBox(
                key: Key('pair-right'),
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.getSize(find.byKey(const Key('pair-right'))).height, 320);
  });

  testWidgets('desktop pair can size the right card to its own content',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: EquityInsiderDesktopPair(
              matchHeight: false,
              left: SizedBox(height: 320, child: ColoredBox(color: Colors.red)),
              right: SizedBox(
                key: Key('pair-right'),
                height: 120,
                child: ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.getSize(find.byKey(const Key('pair-right'))).height, 120);
  });

  testWidgets('desktop pair can copy right height onto the left',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 900,
            child: EquityInsiderDesktopPair(
              matchHeight: false,
              matchFromRight: true,
              fallbackHeight: 200,
              left: ColoredBox(
                key: Key('pair-left'),
                color: Colors.red,
                child: SizedBox(height: 80),
              ),
              right: SizedBox(
                height: 200,
                child: ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(tester.getSize(find.byKey(const Key('pair-left'))).height, 200);
  });

  testWidgets('900 desktop KPI card matches stable chart height',
      (tester) async {
    await _pumpPage(tester, size: const Size(900, 1200));

    expect(find.byType(EquityInsiderDesktopPair), findsOneWidget);
    final kpi = tester.getSize(find.byKey(const Key('ei-kpis-card')));
    final chart = tester.getSize(find.byKey(const Key('ei-chart-card')));
    expect(chart.height, closeTo(362, 8));
    expect(kpi.height, closeTo(chart.height, 1));
    expect(find.textContaining('ROCE'), findsWidgets);
  });

  testWidgets('1100 desktop KPI card matches the same chart height',
      (tester) async {
    await _pumpPage(tester, size: const Size(1100, 1200));

    expect(find.byType(EquityInsiderDesktopPair), findsOneWidget);
    final kpi = tester.getSize(find.byKey(const Key('ei-kpis-card')));
    final chart = tester.getSize(find.byKey(const Key('ei-chart-card')));
    expect(chart.height, closeTo(362, 8));
    expect(kpi.height, closeTo(chart.height, 1));
  });

  testWidgets('empty shareholding skips the shareholding card', (tester) async {
    await _pumpPage(tester, size: const Size(1100, 1200), shareholding: const []);

    expect(find.byKey(const Key('ei-shareholding-card')), findsNothing);
    expect(find.byKey(const Key('ei-financials-card')), findsOneWidget);
  });

  testWidgets('shareholding data keeps the shareholding card', (tester) async {
    await _pumpPage(
      tester,
      size: const Size(1100, 1200),
      shareholding: const [
        {
          'period': 'Mar 2026',
          'promotersPercent': 50.0,
          'fiiPercent': 20.0,
          'diiPercent': 15.0,
          'retailAndOtherPercent': 15.0,
        },
      ],
    );

    expect(find.byKey(const Key('ei-shareholding-card')), findsOneWidget);
    expect(find.byType(EquityInsiderDesktopPair), findsNWidgets(2));
  });

  testWidgets('390 stacks KPI above chart without desktop pair', (tester) async {
    await _pumpPage(tester, size: const Size(390, 844));

    expect(find.byType(EquityInsiderDesktopPair), findsNothing);
    final kpi = tester.getRect(find.byKey(const Key('ei-kpis-card')));
    final chart = tester.getRect(find.byKey(const Key('ei-chart-card')));
    expect(chart.top, greaterThan(kpi.bottom - 1));
  });

  testWidgets('web shareholding packs pie, legend and trend without stretch',
      (tester) async {
    const rows = [
      {
        'period': 'Sep 2025',
        'promotersPercent': 50.0,
        'fiiPercent': 18.6,
        'diiPercent': 10.7,
      },
      {
        'period': 'Mar 2026',
        'promotersPercent': 50.0,
        'fiiPercent': 18.7,
        'diiPercent': 10.8,
      },
    ];
    await _pumpPage(tester, size: const Size(1100, 1200), shareholding: rows);

    final card = find.byKey(const Key('ei-shareholding-card'));
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text('Mutual Funds')),
      findsNothing,
    );
    expect(
      find.descendant(of: card, matching: find.text('Retail & Public')),
      findsNothing,
    );

    final header = tester.getRect(
      find.descendant(of: card, matching: find.text('Shareholding')),
    );
    final trend = tester.getRect(
      find.descendant(of: card, matching: find.text('Holding Trend')),
    );
    expect(trend.top - header.bottom, lessThan(160));

    final dii = tester.getRect(
      find.descendant(of: card, matching: find.text('DII / Others')).last,
    );
    expect(dii.bottom - trend.top, lessThan(130));

    final pie = tester.getRect(find.byType(PieChart));
    final legend = tester.getRect(
      find.descendant(of: card, matching: find.text('Promoters')).first,
    );
    expect(legend.left, greaterThan(pie.right - 8));
    expect((legend.center.dy - pie.center.dy).abs(), lessThan(40));
    expect(tester.getRect(card).bottom - dii.bottom, lessThan(48));
  });
}
