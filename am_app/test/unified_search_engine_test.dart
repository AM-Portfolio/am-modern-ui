import 'dart:async';

import 'package:am_common/am_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:am_app/features/search/adapters/basket_catalog_search_adapter.dart';
import 'package:am_app/features/search/adapters/etf_basket_search_adapter.dart';
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

  testWidgets('empty baskets context includes create-basket action',
      (tester) async {
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

  testWidgets('baskets query surfaces Gold theme before Market',
      (tester) async {
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
}
