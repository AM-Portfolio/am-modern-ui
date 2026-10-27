import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_analytics.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/movers_tile.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/movers_widget.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/portfolio_top_movers_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Stock _stock({
  required String symbol,
  String sector = 'IT',
  double last = 10,
  double pct = 1,
  double? qty,
  double? invested,
  double? avg,
  double? value,
  double? pnl,
}) {
  return Stock(
    symbol: symbol,
    companyName: symbol,
    lastPrice: last,
    changeAmount: last * pct / 100,
    changePercent: pct,
    sector: sector,
    quantity: qty,
    avgPrice: avg,
    investedAmount: invested,
    marketValue: value,
    totalReturn: pnl,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Movers movers, {
  double width = 960,
  bool compact = true,
  int maxRows = 5,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(
            width: width,
            child: MoversWidget(
              movers: movers,
              compact: compact,
              maxRows: maxRows,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('default Today tab is LTP tiles with day percent', (tester) async {
    await _pump(
      tester,
      Movers(
        topGainers: [
          _stock(symbol: 'PARACABLES', last: 68.27, pct: 14.47, qty: 50, value: 3413.5),
        ],
        topLosers: const [],
      ),
    );

    expect(find.text('PARACABLES'), findsOneWidget);
    expect(find.text('₹68.27'), findsOneWidget);
    expect(find.text('+14.47%'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsWidgets);
    expect(find.byType(Table), findsNothing);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('P&L'), findsOneWidget);
    expect(find.text('Cost'), findsOneWidget);
    expect(find.text('LTP'), findsNothing);
    expect(find.text('Qty'), findsNothing);
    expect(find.text('Value'), findsNothing);
    expect(find.text('Invested'), findsNothing);
    expect(find.text('Avg'), findsNothing);
  });

  testWidgets('P&L tab shows rupee P&L and current value without percent',
      (tester) async {
    await _pump(
      tester,
      Movers(
        topGainers: [
          _stock(
            symbol: 'SAKAR',
            last: 18.6,
            pct: 4.51,
            qty: 50,
            value: 930,
          ),
        ],
        topLosers: const [],
      ),
    );

    expect(find.text('₹18.60'), findsOneWidget);
    expect(find.text('+4.51%'), findsOneWidget);

    await tester.tap(find.text('P&L'));
    await tester.pumpAndSettle();
    expect(find.textContaining('41.94'), findsOneWidget);
    expect(find.textContaining('930.00'), findsOneWidget);
    expect(find.text('+4.51%'), findsNothing);
    expect(
      tester.getTopLeft(find.textContaining('41.94')).dx,
      lessThan(tester.getTopLeft(find.textContaining('930.00')).dx),
    );
    expect(find.byKey(const ValueKey('mover-metric-split')), findsOneWidget);
  });

  testWidgets('Cost tab is qty only on mail books', (tester) async {
    await _pump(
      tester,
      Movers(
        topGainers: [
          _stock(symbol: 'SAKAR', last: 18.6, pct: 4.51, qty: 50, value: 930),
        ],
        topLosers: const [],
      ),
    );

    await tester.tap(find.text('Cost'));
    await tester.pumpAndSettle();
    expect(find.text('50'), findsOneWidget);
    expect(find.text('shares'), findsOneWidget);
    expect(find.textContaining('890'), findsNothing);
    expect(find.textContaining('avg'), findsNothing);
    expect(find.text('+4.51%'), findsNothing);
    expect(find.byKey(const ValueKey('mover-metric-split')), findsOneWidget);
  });

  testWidgets('Cost tab shows invested and avg when cost exists', (tester) async {
    await _pump(
      tester,
      Movers(
        topGainers: [
          _stock(
            symbol: 'SAKAR',
            last: 18.6,
            pct: 4.51,
            qty: 50,
            invested: 890,
            avg: 17.8,
            value: 930,
            pnl: 40,
          ),
        ],
        topLosers: const [],
      ),
    );

    await tester.tap(find.text('P&L'));
    await tester.pumpAndSettle();
    expect(find.textContaining('40.00'), findsOneWidget);
    expect(find.textContaining('930.00'), findsOneWidget);

    await tester.tap(find.text('Cost'));
    await tester.pumpAndSettle();
    expect(find.text('50'), findsOneWidget);
    expect(find.text('shares'), findsOneWidget);
    expect(find.textContaining('890'), findsOneWidget);
    expect(find.text('avg ₹17.80'), findsOneWidget);
    expect(find.text('+4.51%'), findsNothing);
    expect(
      tester.getTopLeft(find.text('50')).dx,
      lessThan(tester.getTopLeft(find.textContaining('890')).dx),
    );
    expect(find.byKey(const ValueKey('mover-metric-split')), findsOneWidget);
  });

  testWidgets('960px overview still uses tiles not Table', (tester) async {
    await _pump(
      tester,
      Movers(
        topGainers: [
          _stock(
            symbol: 'SAKAR',
            last: 18.6,
            pct: 4.51,
            qty: 50,
            invested: 890,
            avg: 17.8,
            value: 930,
            pnl: 40,
          ),
        ],
        topLosers: const [],
      ),
      compact: false,
      width: 960,
    );

    expect(find.byType(Table), findsNothing);
    expect(find.text('SAKAR'), findsWidgets);
    expect(find.text('₹18.60'), findsWidgets);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('Overview shows at most five tiles', (tester) async {
    await _pump(
      tester,
      Movers(
        topGainers: [
          for (var i = 1; i <= 7; i++)
            _stock(symbol: 'S$i', qty: i.toDouble(), value: 110),
        ],
        topLosers: const [],
      ),
    );
    expect(find.text('S1'), findsOneWidget);
    expect(find.text('S5'), findsOneWidget);
    expect(find.text('S6'), findsNothing);
  });

  testWidgets('modal content can show ten tiles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 960,
              child: MoversPanelContent(
                forceTabs: true,
                maxRows: 10,
                movers: Movers(
                  topGainers: [
                    for (var i = 1; i <= 12; i++)
                      _stock(symbol: 'M$i', qty: i.toDouble(), value: 110),
                  ],
                  topLosers: const [],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('M1'), findsOneWidget);
    expect(find.text('M10'), findsOneWidget);
    expect(find.text('M11'), findsNothing);
  });

  testWidgets('five tiles sit fully inside the overview peer band',
      (tester) async {
    const bandH = PortfolioTopMoversPanel.peerBandHeight;
    await tester.binding.setSurfaceSize(const Size(380, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 380,
            height: bandH,
            child: MoversWidget(
              compact: true,
              fillHeight: true,
              movers: Movers(
                topGainers: [
                  for (var i = 1; i <= 5; i++) _stock(symbol: 'S$i'),
                ],
                topLosers: const [],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('S1'), findsOneWidget);
    expect(find.text('S5'), findsOneWidget);
    final card = tester.getRect(find.byType(MoversWidget));
    final tiles = find.byType(MoverTile);
    expect(tiles, findsNWidgets(5));
    final last = tester.getRect(tiles.last);
    expect(last.top, greaterThan(card.top));
    expect(last.bottom, lessThanOrEqualTo(card.bottom - 4));
    expect(card.bottom - last.bottom, lessThan(22));
  });

  testWidgets('compact third-column width does not overflow with three chips',
      (tester) async {
    FlutterError.onError = (details) {
      if (details.exception is FlutterError &&
          details.exception.toString().contains('overflowed')) {
        fail(details.exception.toString());
      }
      FlutterError.presentError(details);
    };
    await _pump(
      tester,
      Movers(
        topGainers: [
          _stock(
            symbol: 'SAKAR',
            last: 18.6,
            pct: 4.51,
            qty: 50,
            invested: 890,
            avg: 17.8,
            value: 930,
            pnl: 40,
          ),
        ],
        topLosers: const [],
      ),
      width: 380,
    );
    expect(find.text('SAKAR'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('P&L'), findsOneWidget);
    expect(find.text('Cost'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mixed book Cost tab hides avg on zero-cost row', (tester) async {
    await _pump(
      tester,
      Movers(
        topGainers: [
          _stock(
            symbol: 'GROWW',
            last: 20,
            pct: 2,
            qty: 5,
            invested: 50,
            avg: 10,
            value: 100,
            pnl: 50,
          ),
          _stock(
            symbol: 'DHAN',
            last: 10,
            pct: 1,
            qty: 8,
            value: 80,
          ),
        ],
        topLosers: const [],
      ),
    );
    expect(find.text('DHAN'), findsOneWidget);

    await tester.tap(find.text('Cost'));
    await tester.pumpAndSettle();
    expect(find.text('5'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
    expect(find.text('shares'), findsNWidgets(2));
    expect(find.text('avg ₹10.00'), findsOneWidget);
  });
}
