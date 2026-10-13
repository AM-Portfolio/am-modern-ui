import 'package:am_common/am_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:am_app/features/search/search_context.dart';
import 'package:am_app/features/search/search_navigation.dart';

void main() {
  tearDown(ChartSearchBridge.unbind);

  testWidgets('chart openSecurity prefers ChartSearchBridge when bound',
      (tester) async {
    String? selected;
    ChartSearchBridge.bind(
      recentSymbols: const ['NIFTY 50'],
      selectSymbol: (sym) => selected = sym,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  SearchNavigationHandler(context).openSecurity(
                    'reliance',
                    SearchContext.chart,
                  );
                },
                child: const Text('go'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pump();

    expect(selected, 'RELIANCE');
  });

  testWidgets('chart openSecurity falls back to chart workspace path',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/app/dashboard',
      routes: [
        GoRoute(
          path: '/app/dashboard',
          builder: (_, __) => const Scaffold(body: Text('dash')),
        ),
        GoRoute(
          path: '/app/market/:tab',
          builder: (_, state) => Scaffold(
            body: Text('chart:${state.uri.queryParameters['symbol']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    final ctx = tester.element(find.text('dash'));
    SearchNavigationHandler(ctx).openSecurity('TCS', SearchContext.chart);
    await tester.pumpAndSettle();

    expect(find.text('chart:TCS'), findsOneWidget);
  });
}
