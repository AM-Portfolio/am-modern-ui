import 'package:am_common/am_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:am_app/features/search/search_context.dart';
import 'package:am_app/features/search/search_navigation.dart';

void main() {
  tearDown(ChartSearchBridge.unbind);

  GoRouter chartRouter({String initial = '/app/dashboard'}) {
    return GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(
          path: '/app/dashboard',
          builder: (_, __) => const Scaffold(body: Text('dash')),
        ),
        GoRoute(
          path: '/app/market/:tab',
          builder: (_, state) => Scaffold(
            body: Text(
              '${state.pathParameters['tab']}:${state.uri.queryParameters['symbol']}',
            ),
          ),
        ),
      ],
    );
  }

  testWidgets('chart openSecurity selects via bridge and syncs URL',
      (tester) async {
    String? selected;
    ChartSearchBridge.bind(
      recentSymbols: const ['NIFTY 50'],
      selectSymbol: (sym) => selected = sym,
    );

    final router = chartRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final ctx = tester.element(find.text('dash'));
    SearchNavigationHandler(ctx).openSecurity('reliance', SearchContext.chart);
    await tester.pumpAndSettle();

    expect(selected, 'RELIANCE');
    expect(find.text('chart:RELIANCE'), findsOneWidget);
  });

  testWidgets('chart openSecurity falls back to chart workspace path',
      (tester) async {
    final router = chartRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final ctx = tester.element(find.text('dash'));
    SearchNavigationHandler(ctx).openSecurity('TCS', SearchContext.chart);
    await tester.pumpAndSettle();

    expect(find.text('chart:TCS'), findsOneWidget);
  });

  testWidgets('market/dashboard/other openSecurity opens chart workspace',
      (tester) async {
    for (final ctxKind in [
      SearchContext.market,
      SearchContext.dashboard,
      SearchContext.other,
    ]) {
      final router = chartRouter();
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      final ctx = tester.element(find.text('dash'));
      SearchNavigationHandler(ctx).openSecurity('INFY', ctxKind);
      await tester.pumpAndSettle();

      expect(find.text('chart:INFY'), findsOneWidget);
    }
  });
}
