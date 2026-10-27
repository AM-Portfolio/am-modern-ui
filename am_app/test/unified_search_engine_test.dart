import 'dart:async';

import 'package:am_common/am_common.dart';
import 'package:am_market_ui/features/equity_insider/providers/equity_insider_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:am_app/features/search/adapters/basket_catalog_search_adapter.dart';
import 'package:am_app/features/search/adapters/etf_basket_search_adapter.dart';
import 'package:am_app/features/search/adapters/holdings_search_adapter.dart';
import 'package:am_app/features/search/adapters/securities_search_adapter.dart';
import 'package:am_app/features/search/search_context.dart';
import 'package:am_app/features/search/unified_search_engine.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/etf_search_result.dart';

class _FakeSecurities extends SecuritiesSearchAdapter {
  _FakeSecurities(this._handler);

  final Future<List<SecuritiesHit>> Function(String query) _handler;

  @override
  Future<List<SecuritiesHit>> search(
    String query, {
    String category = 'ALL',
  }) =>
      _handler(query);
}

class _FakeEtf extends EtfBasketSearchAdapter {
  _FakeEtf(this._handler);

  final Future<List<EtfBasketHit>> Function(String query) _handler;

  @override
  Future<List<EtfBasketHit>> search(String query, {int limit = 8}) =>
      _handler(query);
}

BasketCatalogSearchAdapter _catalogWithGold() {
  return BasketCatalogSearchAdapter(
    catalogLoader: () async => const [
      BasketThemeHit(
        id: 'gold',
        label: 'Gold',
        query: 'GOLDBEES',
        featured: true,
      ),
    ],
  );
}

void main() {
  testWidgets('stale results never overwrite a newer query', (tester) async {
    final slow = Completer<List<SecuritiesHit>>();
    final fast = Completer<List<SecuritiesHit>>();

    final engine = UnifiedSearchEngine(
      debounce: Duration.zero,
      securities: _FakeSecurities((q) {
        if (q == 'aaa') return slow.future;
        return fast.future;
      }),
      etfBasket: _FakeEtf((_) async => const []),
    );

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    final navContext = navKey.currentContext!;

    final emissions = <UnifiedSearchSnapshot>[];
    engine.query(
      rawQuery: 'aaa',
      context: SearchContext.market,
      navContext: navContext,
      seedActions: const [],
      onResult: emissions.add,
    );
    // Let the first debounce fire so the slow request is in flight.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    engine.query(
      rawQuery: 'bbb',
      context: SearchContext.market,
      navContext: navContext,
      seedActions: const [],
      onResult: emissions.add,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    fast.complete([
      const SecuritiesHit(symbol: 'BBB', name: 'BBB Corp'),
    ]);
    await tester.pump();

    // Late stale response for first query must be ignored.
    slow.complete([
      const SecuritiesHit(symbol: 'AAA', name: 'AAA Corp'),
    ]);
    await tester.pump();

    final finals =
        emissions.where((e) => !e.isLoading && e.query.isNotEmpty).toList();
    expect(finals, isNotEmpty);
    expect(finals.every((e) => e.query == 'bbb'), isTrue);
    expect(
      finals.last.items.any((i) => i.title == 'BBB'),
      isTrue,
    );
    expect(
      finals.any((e) => e.items.any((i) => i.title == 'AAA')),
      isFalse,
    );

    engine.dispose();
  });

  testWidgets('empty baskets context includes create-basket action', (tester) async {
    final catalog = _catalogWithGold();
    final engine = UnifiedSearchEngine(
      debounce: Duration.zero,
      securities: _FakeSecurities((_) async => const []),
      etfBasket: _FakeEtf((_) async => const []),
      catalog: catalog,
    );

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        home: const Scaffold(body: SizedBox()),
      ),
    );

    List<CommandItem>? items;
    engine.query(
      rawQuery: '',
      context: SearchContext.baskets,
      navContext: navKey.currentContext!,
      seedActions: [
        CommandItem(
          title: 'Portfolio Overview',
          subtitle: 'Go to overview',
          icon: Icons.pie_chart,
          category: 'Portfolio',
          onSelected: () {},
        ),
      ],
      onResult: (snap) => items = snap.items,
    );
    await tester.pump();
    await tester.pump();

    expect(items, isNotNull);
    expect(
      items!.any((i) => i.title.toLowerCase().contains('create')),
      isTrue,
    );
    expect(items!.any((i) => i.title == 'Gold'), isTrue);
    engine.dispose();
  });

  test('rememberSymbol keeps recent unique order', () {
    final engine = UnifiedSearchEngine(
      securities: _FakeSecurities((_) async => const []),
      etfBasket: _FakeEtf((_) async => const []),
    );
    engine.rememberSymbol('INFY');
    engine.rememberSymbol('TCS');
    engine.rememberSymbol('INFY');
    expect(engine.recentSymbols, ['INFY', 'TCS']);
    engine.dispose();
  });

  testWidgets('chart empty suggestions show Recent chart from bridge',
      (tester) async {
    ChartSearchBridge.bind(
      recentSymbols: const ['PNB', 'BANKNIFTY', 'TCS'],
      selectSymbol: (_) {},
    );
    addTearDown(ChartSearchBridge.unbind);

    final engine = UnifiedSearchEngine(
      debounce: Duration.zero,
      securities: _FakeSecurities((_) async => const []),
      etfBasket: _FakeEtf((_) async => const []),
    );

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        home: const Scaffold(body: SizedBox()),
      ),
    );

    List<CommandItem>? items;
    engine.query(
      rawQuery: '',
      context: SearchContext.chart,
      navContext: navKey.currentContext!,
      seedActions: const [],
      onResult: (snap) => items = snap.items,
    );
    await tester.pump();

    expect(items, isNotNull);
    final chartRecents = items!
        .where((i) => i.subtitle == 'Recent chart')
        .map((i) => i.title)
        .toList();
    expect(chartRecents, ['PNB', 'BANKNIFTY', 'TCS']);
    engine.dispose();
  });

  testWidgets('baskets query surfaces Gold theme before Market', (tester) async {
    final engine = UnifiedSearchEngine(
      debounce: Duration.zero,
      securities: _FakeSecurities(
        (_) async => const [
          SecuritiesHit(symbol: 'GOLD', name: 'Some Gold Stock'),
        ],
      ),
      etfBasket: _FakeEtf(
        (_) async => [
          EtfBasketHit(
            title: 'Nippon Gold BeES',
            subtitle: 'GOLDBEES',
            result: const EtfSearchResult(
              symbol: 'GOLDBEES',
              name: 'Nippon Gold BeES',
            ),
          ),
        ],
      ),
      catalog: _catalogWithGold(),
    );

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        home: const Scaffold(body: SizedBox()),
      ),
    );

    UnifiedSearchSnapshot? last;
    engine.query(
      rawQuery: 'Gold',
      context: SearchContext.baskets,
      navContext: navKey.currentContext!,
      seedActions: const [],
      onResult: (snap) => last = snap,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(last, isNotNull);
    expect(last!.isLoading, isFalse);
    final titles = last!.items.map((i) => i.title).toList();
    expect(titles, contains('Gold'));
    final gold = last!.items.firstWhere((i) => i.title == 'Gold');
    expect(gold.category, 'Baskets');
    // Theme preferred over duplicate ETF symbol GOLDBEES.
    expect(
      last!.items.where((i) => i.subtitle.contains('GOLDBEES')).length,
      1,
    );
    expect(titles.indexOf('Gold'), lessThan(titles.indexOf('GOLD')));

    engine.dispose();
  });

  testWidgets('equity insider empty suggestion tap writes active symbol',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final engine = UnifiedSearchEngine(
      debounce: Duration.zero,
      securities: _FakeSecurities((_) async => const []),
      etfBasket: _FakeEtf((_) async => const []),
    );

    final router = GoRouter(
      initialLocation: '/app/market/equity-insider',
      routes: [
        GoRoute(
          path: '/app/market/:tab',
          builder: (_, state) => Scaffold(
            body: Text(state.pathParameters['tab'] ?? ''),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    List<CommandItem>? items;
    engine.query(
      rawQuery: '',
      context: SearchContext.equityInsider,
      navContext: tester.element(find.text('equity-insider')),
      seedActions: const [],
      container: container,
      onResult: (snap) => items = snap.items,
    );
    await tester.pump();

    expect(items, isNotNull);
    final tcs = items!.firstWhere((i) => i.title == 'TCS');
    tcs.onSelected();
    expect(container.read(equityInsiderActiveSymbolProvider), 'TCS');
    engine.dispose();
  });

  testWidgets('pnb ranks exact PNB first in equity insider and market',
      (tester) async {
    const hits = [
      SecuritiesHit(symbol: '810PNB24', name: 'PNB 8.15% SR LXVI'),
      SecuritiesHit(symbol: 'PNBGILTS', name: 'PNB GILTS LTD'),
      SecuritiesHit(symbol: 'PNB', name: 'PUNJAB NATIONAL BANK'),
      SecuritiesHit(symbol: '830PNBPERP', name: 'PNB 8.30% PERPETUAL'),
    ];
    final engine = UnifiedSearchEngine(
      debounce: Duration.zero,
      securities: _FakeSecurities((_) async => hits),
      etfBasket: _FakeEtf((_) async => const []),
    );
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        home: const Scaffold(body: SizedBox()),
      ),
    );

    for (final ctx in [SearchContext.equityInsider, SearchContext.market]) {
      UnifiedSearchSnapshot? last;
      engine.query(
        rawQuery: 'pnb',
        context: ctx,
        navContext: navKey.currentContext!,
        seedActions: const [],
        onResult: (snap) => last = snap,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(last, isNotNull);
      expect(last!.items.first.title, 'PNB');
    }
    engine.dispose();
  });

  testWidgets('nifty ranks exact NIFTY first in F&O', (tester) async {
    final engine = UnifiedSearchEngine(
      debounce: Duration.zero,
      securities: _FakeSecurities(
        (_) async => const [
          SecuritiesHit(symbol: 'NIFTY24APR', name: 'NIFTY 24 APR'),
          SecuritiesHit(symbol: 'NIFTYBEES', name: 'Nippon Nifty BeES'),
          SecuritiesHit(symbol: 'NIFTY', name: 'NIFTY 50'),
        ],
      ),
      etfBasket: _FakeEtf((_) async => const []),
    );
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    UnifiedSearchSnapshot? last;
    engine.query(
      rawQuery: 'nifty',
      context: SearchContext.fo,
      navContext: navKey.currentContext!,
      seedActions: const [],
      onResult: (snap) => last = snap,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(last!.items.first.title, 'NIFTY');
    engine.dispose();
  });

  testWidgets('portfolio irfc ranks holding before market bonds',
      (tester) async {
    final engine = UnifiedSearchEngine(
      debounce: Duration.zero,
      securities: _FakeSecurities(
        (_) async => const [
          SecuritiesHit(symbol: '687IRFC32', name: 'IRFC 6.87% 14-4-32'),
          SecuritiesHit(symbol: '695IRFC36', name: 'IRFC 6.95% 24-11-36'),
          SecuritiesHit(symbol: 'IRFC', name: 'INDIAN RAILWAY FINANCE'),
        ],
      ),
      etfBasket: _FakeEtf((_) async => const []),
      catalog: _catalogWithGold(),
      holdings: HoldingsSearchAdapter(
        debugHoldings: () => const [
          HoldingsHit(
            symbol: 'IRFC',
            name: 'IRFC',
            companyName: 'INDIAN RAILWAY FINANCE CORPORATION',
          ),
        ],
      ),
    );
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    UnifiedSearchSnapshot? last;
    engine.query(
      rawQuery: 'irfc',
      context: SearchContext.portfolio,
      navContext: navKey.currentContext!,
      seedActions: const [],
      onResult: (snap) => last = snap,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(last!.items.first.title, 'IRFC');
    expect(last!.items.first.category, 'Portfolio');
    expect(last!.items.where((i) => i.title == 'IRFC').length, 1);
    expect(last!.items.any((i) => i.title == '687IRFC32'), isTrue);
    engine.dispose();
  });

  testWidgets('portfolio empty query suggests cached holdings', (tester) async {
    final engine = UnifiedSearchEngine(
      debounce: Duration.zero,
      securities: _FakeSecurities((_) async => const []),
      etfBasket: _FakeEtf((_) async => const []),
      catalog: _catalogWithGold(),
      holdings: HoldingsSearchAdapter(
        debugHoldings: () => const [
          HoldingsHit(
            symbol: 'IRFC',
            name: 'IRFC',
            companyName: 'INDIAN RAILWAY FINANCE CORPORATION',
          ),
        ],
      ),
    );
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    List<CommandItem>? items;
    engine.query(
      rawQuery: '',
      context: SearchContext.portfolio,
      navContext: navKey.currentContext!,
      seedActions: const [],
      onResult: (snap) => items = snap.items,
    );
    await tester.pump();
    await tester.pump();
    expect(items!.any((i) => i.title == 'IRFC' && i.category == 'Portfolio'),
        isTrue);
    engine.dispose();
  });

  testWidgets('equity insider irfc does not inject holdings', (tester) async {
    final engine = UnifiedSearchEngine(
      debounce: Duration.zero,
      securities: _FakeSecurities(
        (_) async => const [
          SecuritiesHit(symbol: '687IRFC32', name: 'IRFC bond'),
          SecuritiesHit(symbol: 'IRFC', name: 'INDIAN RAILWAY FINANCE'),
        ],
      ),
      etfBasket: _FakeEtf((_) async => const []),
      holdings: HoldingsSearchAdapter(
        debugHoldings: () => const [
          HoldingsHit(
            symbol: 'IRFC',
            name: 'IRFC',
            companyName: 'INDIAN RAILWAY',
          ),
        ],
      ),
    );
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        home: const Scaffold(body: SizedBox()),
      ),
    );
    UnifiedSearchSnapshot? last;
    engine.query(
      rawQuery: 'irfc',
      context: SearchContext.equityInsider,
      navContext: navKey.currentContext!,
      seedActions: const [],
      onResult: (snap) => last = snap,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(last!.items.any((i) => i.category == 'Portfolio'), isFalse);
    expect(last!.items.first.title, 'IRFC');
    engine.dispose();
  });
}
