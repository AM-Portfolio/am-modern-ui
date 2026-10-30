import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_analytics.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/movers_tabs.dart';
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
  double? weight,
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
    weight: weight,
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
  testWidgets('Value mode keeps Today LTP and shows compact value + invested + day ₹',
      (tester) async {
    await _pump(
      tester,
      Movers(
        topGainers: [
          _stock(
            symbol: 'PARACABLES',
            last: 68.27,
            pct: 14.47,
            qty: 50,
            value: 3413.5,
            invested: 3000,
            pnl: 413.5,
          ),
        ],
        topLosers: const [],
      ),
    );

    expect(find.text('PARACABLES'), findsOneWidget);
    expect(find.text('50 shares'), findsOneWidget);
    expect(find.text('₹68.27'), findsOneWidget);
    expect(find.textContaining('+₹9.88'), findsOneWidget);
    expect(find.textContaining('+14.47%'), findsOneWidget);
    // Compact K notation on totals only (Today LTP stays exact).
    expect(find.textContaining('₹3.4K'), findsOneWidget);
    expect(find.textContaining('Inv'), findsOneWidget);
    expect(find.textContaining('₹3.0K'), findsOneWidget);
    expect(find.textContaining('+₹493.93'), findsOneWidget);
    expect(find.text('Biggest gainers from your portfolio'), findsNothing);
    expect(find.text('See Top 10'), findsNothing);
    expect(find.text('Value'), findsOneWidget);
    expect(find.text('Percentage'), findsOneWidget);
  });

  testWidgets('Percentage mode does not change Today column', (tester) async {
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
            invested: 890,
            pnl: 40,
            weight: 2.5,
          ),
        ],
        topLosers: const [],
      ),
    );

    expect(find.text('₹18.60'), findsOneWidget);
    expect(find.textContaining('+₹0.84'), findsOneWidget);

    await tester.tap(find.text('Percentage'));
    await tester.pumpAndSettle();

    // Today column unchanged.
    expect(find.text('₹18.60'), findsOneWidget);
    expect(find.textContaining('+₹0.84'), findsOneWidget);
    expect(find.textContaining('+4.51%'), findsWidgets);
    // Right column: today's return % (day ₹ / invested), not lifetime P&L %.
    // 50 * 18.6 * 4.51/100 / 890 ≈ 4.71%
    expect(find.textContaining('+4.71%'), findsOneWidget);
    expect(find.textContaining('2.5% of portfolio'), findsOneWidget);
  });

  testWidgets('Percentage mode shows signed day loss, not lifetime gain',
      (tester) async {
    // Lifetime +200% but today down — % column must show the day loss.
    await _pump(
      tester,
      Movers(
        topGainers: const [],
        topLosers: [
          _stock(
            symbol: 'SAKAR',
            last: 950,
            pct: -3.94,
            qty: 16,
            value: 15200,
            invested: 5030,
            pnl: 10170, // ~+202% lifetime
            weight: 1.7,
          ),
        ],
      ),
    );
    await tester.tap(find.text('Losers'));
    await tester.pumpAndSettle();
    final pctToggle = find.text('Percentage');
    await tester.tap(pctToggle.evaluate().isEmpty ? find.text('%') : pctToggle);
    await tester.pumpAndSettle();

    expect(find.textContaining('+202'), findsNothing);
    // day ₹ = 16*(950*-3.94/100) ≈ -598.9; /5030 ≈ -11.91%
    expect(find.textContaining('-11.91%'), findsOneWidget);
    expect(find.textContaining('1.7% of portfolio'), findsOneWidget);
  });

  testWidgets('960px overview still uses tabs and tiles not Table',
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
    expect(find.text('Value'), findsOneWidget);
    expect(find.text('Gainers'), findsOneWidget);
  });

  testWidgets('Overview shows at most five tiles', (tester) async {
    await _pump(
      tester,
      Movers(
        topGainers: [
          for (var i = 1; i <= 7; i++)
            _stock(symbol: 'S$i', qty: i.toDouble(), value: 110, pct: 1),
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
                maxRows: 10,
                mode: MoversDisplayMode.value,
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
    // Five equal slots fill the card — last row sits near the bottom edge.
    expect(card.bottom - last.bottom, lessThan(28));
  });

  testWidgets('compact width keeps Value/Percentage in header without overflow',
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
    expect(find.text('Value'), findsOneWidget);
    // Narrow trailing slot uses "%" instead of "Percentage".
    expect(
      find.text('Percentage').evaluate().isNotEmpty ||
          find.text('%').evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.text('See Top 10'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Losers tab shows losers without subtitle', (tester) async {
    await _pump(
      tester,
      Movers(
        topGainers: [_stock(symbol: 'UP')],
        topLosers: [_stock(symbol: 'DOWN', pct: -2)],
      ),
    );
    expect(find.text('Biggest gainers from your portfolio'), findsNothing);
    expect(find.text('UP'), findsOneWidget);
    await tester.tap(find.text('Losers'));
    await tester.pumpAndSettle();
    expect(find.text('Biggest losers from your portfolio'), findsNothing);
    expect(find.text('DOWN'), findsOneWidget);
  });

  testWidgets('long symbol stays visible under shares pill', (tester) async {
    await _pump(
      tester,
      Movers(
        topGainers: [
          _stock(
            symbol: 'KOTAKBANK',
            last: 459,
            pct: 4.32,
            qty: 74,
            value: 33966,
            invested: 26338.08,
            pnl: 7627.92,
          ),
        ],
        topLosers: const [],
      ),
      width: 380,
    );
    expect(find.text('KOTAKBANK'), findsOneWidget);
    expect(find.text('74 shares'), findsOneWidget);
    expect(find.textContaining('₹34.0K'), findsOneWidget);
    expect(find.textContaining('₹26.3K'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
