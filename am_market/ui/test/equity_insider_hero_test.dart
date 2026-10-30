import 'dart:async';

import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/equity_insider/presentation/widgets/equity_insider_chart.dart';
import 'package:am_market_ui/features/equity_insider/presentation/widgets/equity_insider_hero.dart';
import 'package:am_market_ui/features/equity_insider/providers/equity_insider_provider.dart';
import 'package:am_market_ui/features/watchlists/data/models/watchlist_model.dart';
import 'package:am_market_ui/features/watchlists/providers/watchlist_provider.dart';
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

_overrides({
  double? price = 1209,
  double? change = 7,
  double? pct = 0.58,
  Future<List<WatchlistCheckStatus>> Function()? watchlistCheck,
  MultiSeriesChartData chartData = const MultiSeriesChartData(series: {}),
}) {
  return [
    fundamentalProfileProvider.overrideWith((ref, query) async {
      return FundamentalRatiosResponse(
        symbol: 'RELIANCE',
        companyName: 'RELIANCE INDUSTRIES LTD',
        currentPrice: price,
        dayChange: change,
        dayChangePercent: pct,
        sector: 'Oil & Gas',
        industry: 'Refining',
      );
    }),
    watchlistCheckStatusProvider.overrideWith((ref, symbol) {
      if (watchlistCheck != null) return watchlistCheck();
      return Future<List<WatchlistCheckStatus>>.value(
        const <WatchlistCheckStatus>[],
      );
    }),
    equityStockChartDataProvider.overrideWith((ref, query) async {
      return chartData;
    }),
  ];
}

Future<ProviderContainer> _pumpHero(
  WidgetTester tester, {
  required Size size,
  double? height,
  List<dynamic>? overrides,
}) async {
  final container = ProviderContainer(
    overrides: List.from(overrides ?? _overrides()),
  );
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
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: height ?? size.height,
            child: const EquityInsiderHeroBar(symbol: 'RELIANCE'),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return container;
}

void main() {
  testWidgets('desktop strip is ticker, NSE/BSE, Live, Add to Watchlist',
      (tester) async {
    await _pumpHero(tester, size: const Size(1100, 844), height: 120);

    expect(find.byKey(const Key('ei-header-ticker')), findsOneWidget);
    expect(find.text('RELIANCE'), findsOneWidget);
    expect(find.text('NSE'), findsOneWidget);
    expect(find.text('BSE'), findsOneWidget);
    expect(find.textContaining('National Stock Exchange'), findsOneWidget);
    expect(find.textContaining('Live'), findsOneWidget);
    expect(find.text('Add to Watchlist'), findsOneWidget);
    expect(find.text('Oil & Gas'), findsNothing);
    expect(find.text('Refining'), findsNothing);
    expect(find.byIcon(Icons.star_border_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping BSE updates selectedExchangeProvider', (tester) async {
    final container = await _pumpHero(tester, size: const Size(1100, 844));
    expect(container.read(selectedExchangeProvider), 'NSE');
    await tester.tap(find.text('BSE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(container.read(selectedExchangeProvider), 'BSE');
    expect(find.textContaining('Bombay Stock Exchange'), findsOneWidget);
  });

  testWidgets('mobile 390 uses compact chips and star', (tester) async {
    final container = await _pumpHero(tester, size: const Size(390, 844));
    expect(find.text('NSE'), findsOneWidget);
    expect(find.text('BSE'), findsOneWidget);
    expect(find.text('Add to Watchlist'), findsNothing);
    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
    expect(container.read(selectedExchangeProvider), 'NSE');
    await tester.tap(find.text('BSE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(container.read(selectedExchangeProvider), 'BSE');
  });

  Future<void> _pumpChart(
    WidgetTester tester, {
    required Size size,
  }) async {
    const chartData = MultiSeriesChartData(
      series: {
        'RELIANCE': [
          MultiSeriesPoint(time: '2025-12-01', value: 1500),
          MultiSeriesPoint(time: '2026-02-23', value: 1428),
          MultiSeriesPoint(time: '2026-06-01', value: 1280),
        ],
      },
    );
    final container = ProviderContainer(
      overrides: _overrides(chartData: chartData),
    );
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
          home: Scaffold(
            body: SizedBox(
              width: size.width,
              height: 400,
              child: const EquityInsiderChart(symbol: 'RELIANCE'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  void _expectTitleAndToggleLayout(WidgetTester tester) {
    expect(find.text('Performance Chart'), findsOneWidget);
    expect(find.text('Price Performance & Chart'), findsNothing);
    expect(find.text('Price Performance'), findsNothing);
    expect(find.byType(CustomDropdown<TimeFrame>), findsOneWidget);
    expect(find.byType(TimeFrameSelector), findsNothing);

    final titleFinder = find.byKey(const Key('ei-chart-title'));
    final timeframeFinder = find.byType(CustomDropdown<TimeFrame>);
    final toggleFinder = find.byKey(const Key('comparison-chart-unit-toggle'));
    final legendFinder = find.text('RELIANCE');

    final title = tester.getRect(titleFinder);
    expect(title.width, greaterThan(110));
    expect(title.right, lessThan(tester.getRect(timeframeFinder).left));

    final timeframe = tester.getSize(timeframeFinder);
    final unitToggle = tester.getSize(toggleFinder);
    expect(timeframe.width, unitToggle.width);
    expect(timeframe.height, unitToggle.height);

    final timeframePos = tester.getTopLeft(timeframeFinder);
    final togglePos = tester.getTopLeft(toggleFinder);
    expect(
      (tester.getRect(timeframeFinder).center.dy - title.center.dy).abs(),
      lessThan(2),
    );
    expect(togglePos.dy, greaterThan(timeframePos.dy + 8));
    expect((togglePos.dx - timeframePos.dx).abs(), lessThan(2));
    expect(
      (tester.getRect(toggleFinder).center.dy -
              tester.getRect(legendFinder).center.dy)
          .abs(),
      lessThan(4),
    );
  }

  testWidgets('desktop: percent toggle sits under timeframe on RELIANCE row',
      (tester) async {
    await _pumpChart(tester, size: const Size(1100, 844));
    _expectTitleAndToggleLayout(tester);
  });

  testWidgets('mobile: Performance Chart title stays fully visible',
      (tester) async {
    await _pumpChart(tester, size: const Size(390, 844));
    _expectTitleAndToggleLayout(tester);
  });

  testWidgets('Add to Watchlist stays visible while check is loading',
      (tester) async {
    await _pumpHero(
      tester,
      size: const Size(1100, 844),
      height: 120,
      overrides: _overrides(
        watchlistCheck: () => Completer<List<WatchlistCheckStatus>>().future,
      ),
    );

    expect(find.text('Add to Watchlist'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
