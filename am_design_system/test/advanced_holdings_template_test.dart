// ignore_for_file: lines_longer_than_80_chars

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Shared fixtures
// ---------------------------------------------------------------------------

AdvancedHoldingRow _row({
  required String symbol,
  required String sector,
  required String industry,
  required double gl,
}) {
  final isGain = gl >= 0;
  return AdvancedHoldingRow(
    id: symbol,
    symbol: symbol,
    companyName:
        '${symbol.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '').capitalize()} Ltd',
    sector: sector,
    industry: industry,
    quantity: 10,
    avgPrice: 100,
    currentPrice: isGain ? 110 : 90,
    investedAmount: 1000,
    currentValue: isGain ? 1100 : 900,
    totalGainLoss: gl,
    totalGainLossPercentage: gl / 10,
    todayChange: isGain ? 1.0 : -1.0,
    todayChangePercentage: isGain ? 0.9 : -1.0,
    portfolioWeight: 5,
  );
}

// 5 holdings:
//   Profit: TCS (IT/Software), INFY (IT/Software), TMCV (Auto/EV)
//   Loss:   APAT (Auto/Tyres), HCLTECH (IT/Hardware)
List<AdvancedHoldingRow> get _testHoldings => [
      _row(symbol: 'TCS', sector: 'IT', industry: 'Software', gl: 500),
      _row(symbol: 'INFY', sector: 'IT', industry: 'Software', gl: 200),
      _row(symbol: 'TMCV', sector: 'Auto', industry: 'EV', gl: 100),
      _row(symbol: 'APAT', sector: 'Auto', industry: 'Tyres', gl: -50),
      _row(symbol: 'HCLTECH', sector: 'IT', industry: 'Hardware', gl: -30),
    ];

Future<void> _pump(
  WidgetTester tester,
  List<AdvancedHoldingRow> holdings, {
  String? priceFreshnessLabel,
  String? initialSector,
  Size surfaceSize = const Size(1400, 900),
}) async {
  await tester.binding.setSurfaceSize(surfaceSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: AdvancedHoldingsTemplate(
          holdings: holdings,
          isLoading: false,
          initialSector: initialSector,
          priceFreshnessLabel: priceFreshnessLabel ?? 'As of 2026-10-28 13:55',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Counts visible symbol texts in the table body.
int _visibleSymbolCount(WidgetTester tester, List<String> symbols) {
  return symbols.where((s) => tester.any(find.text(s))).length;
}

extension on String {
  String capitalize() =>
      this.isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Group 1: Initial rendering -----------------------------------------------

  testWidgets('T01 renders status filter pills', (tester) async {
    await _pump(tester, _testHoldings);
    expect(find.text('All'), findsWidgets);
    expect(find.text('Profit'), findsOneWidget);
    expect(find.text('Loss'), findsOneWidget);
  });

  testWidgets('T02 renders Table and Card view mode buttons', (tester) async {
    await _pump(tester, _testHoldings);
    expect(find.text('Table'), findsOneWidget);
    expect(find.text('Card'), findsOneWidget);
  });

  testWidgets('T03 renders Sector and Industry dropdowns', (tester) async {
    await _pump(tester, _testHoldings);
    // "Sector" appears on filter chip + table column header.
    expect(find.text('Sector'), findsWidgets);
    expect(find.text('Industry'), findsOneWidget);
    expect(find.text('All Sectors'), findsNothing);
    expect(find.text('All Industries'), findsNothing);
  });

  testWidgets('T04 renders Search field and Reset button', (tester) async {
    await _pump(tester, _testHoldings);
    expect(find.widgetWithText(TextField, ''), findsWidgets);
    expect(find.text('Reset'), findsOneWidget);
  });

  testWidgets('T05 Exchange and Instrument Type are absent', (tester) async {
    await _pump(tester, _testHoldings);
    expect(find.text('Exchange'), findsNothing);
    expect(find.text('Instrument Type'), findsNothing);
  });

  testWidgets('T06 top row shows timestamp beside Table/Card', (tester) async {
    await _pump(tester, _testHoldings,
        priceFreshnessLabel: 'As of 2026-10-28 13:55');
    expect(find.textContaining('As of'), findsOneWidget);
  });

  testWidgets('T07 holdings count badge is not shown in header',
      (tester) async {
    await _pump(tester, _testHoldings);
    expect(find.text('5 holdings'), findsNothing);
    expect(find.textContaining('of 5'), findsOneWidget);
  });

  // Group 2: Status filter ----------------------------------------------------

  testWidgets('T08 Profit filter hides loss holdings', (tester) async {
    await _pump(tester, _testHoldings);

    await tester.tap(find.text('Profit'));
    await tester.pumpAndSettle();

    // APAT and HCLTECH are losses — they must disappear from table rows.
    // TCS, INFY, TMCV are profits — they must remain.
    expect(find.text('APAT'), findsNothing);
    expect(find.text('HCLTECH'), findsNothing);
    expect(find.text('TCS'), findsWidgets);
    expect(find.text('INFY'), findsWidgets);
    expect(find.text('TMCV'), findsWidgets);
  });

  testWidgets('T09 Loss filter hides profit holdings', (tester) async {
    await _pump(tester, _testHoldings);

    await tester.tap(find.text('Loss'));
    await tester.pumpAndSettle();

    expect(find.text('TCS'), findsNothing);
    expect(find.text('INFY'), findsNothing);
    expect(find.text('TMCV'), findsNothing);
    expect(find.text('APAT'), findsWidgets);
    expect(find.text('HCLTECH'), findsWidgets);
  });

  testWidgets('T10 All filter restores full list', (tester) async {
    await _pump(tester, _testHoldings);

    await tester.tap(find.text('Profit'));
    await tester.pumpAndSettle();
    // Confirm filtered.
    expect(find.text('APAT'), findsNothing);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();

    // All 5 symbols present.
    expect(
        _visibleSymbolCount(tester, ['TCS', 'INFY', 'TMCV', 'APAT', 'HCLTECH']),
        equals(5));
  });

  // Group 3: Sector & Industry cascade ----------------------------------------

  testWidgets('T11 Sector filter — IT shows only IT holdings', (tester) async {
    await _pump(tester, _testHoldings);

    // Open Sector dropdown and pick IT.
    await tester.tap(find.text('Sector').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('IT').last);
    await tester.pumpAndSettle();

    expect(find.text('TCS'), findsWidgets);
    expect(find.text('INFY'), findsWidgets);
    expect(find.text('HCLTECH'), findsWidgets);
    expect(find.text('TMCV'), findsNothing);
    expect(find.text('APAT'), findsNothing);
  });

  testWidgets('T12 Sector filter — Auto shows only Auto holdings',
      (tester) async {
    await _pump(tester, _testHoldings);

    await tester.tap(find.text('Sector').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto').last);
    await tester.pumpAndSettle();

    expect(find.text('TMCV'), findsWidgets);
    expect(find.text('APAT'), findsWidgets);
    expect(find.text('TCS'), findsNothing);
  });

  testWidgets('T13 Industry dropdown cascades — only Auto industries shown',
      (tester) async {
    await _pump(tester, _testHoldings);

    // Select Auto sector first.
    await tester.tap(find.text('Sector').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto').last);
    await tester.pumpAndSettle();

    // Now open Industry dropdown.
    await tester.tap(find.text('Industry'));
    await tester.pumpAndSettle();

    // Should see EV and Tyres but NOT Software or Hardware (IT industries).
    expect(find.text('EV'), findsWidgets);
    expect(find.text('Tyres'), findsWidgets);
    expect(find.text('Software'), findsNothing);
    expect(find.text('Hardware'), findsNothing);

    // Close popup.
    await tester.tap(find.text('EV').last);
    await tester.pumpAndSettle();
  });

  testWidgets('T14 Industry filter narrows to EV within Auto sector',
      (tester) async {
    await _pump(tester, _testHoldings);

    await tester.tap(find.text('Sector').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Industry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('EV').last);
    await tester.pumpAndSettle();

    expect(find.text('TMCV'), findsWidgets);
    expect(find.text('APAT'), findsNothing);
  });

  testWidgets('T15 sector change auto-resets orphaned industry',
      (tester) async {
    await _pump(tester, _testHoldings);

    // Select IT + Software.
    await tester.tap(find.text('Sector').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('IT').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Industry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Software').last);
    await tester.pumpAndSettle();

    // Now change sector to Auto — Software is not in Auto, must auto-reset.
    await tester.tap(find.text('IT').first); // current sector label in dropdown
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto').last);
    await tester.pumpAndSettle();

    // Industry chip back to placeholder.
    expect(find.text('Industry'), findsOneWidget);
    // Both Auto holdings visible.
    expect(find.text('TMCV'), findsWidgets);
    expect(find.text('APAT'), findsWidgets);
  });

  // Group 4: Search -----------------------------------------------------------

  testWidgets('T16 search by symbol', (tester) async {
    await _pump(tester, _testHoldings);

    await tester.enterText(find.byType(TextField), 'TCS');
    await tester.pumpAndSettle();

    expect(find.text('TCS'), findsWidgets);
    expect(find.text('INFY'), findsNothing);
    expect(find.text('TMCV'), findsNothing);
  });

  testWidgets('T17 search by company name (partial)', (tester) async {
    await _pump(tester, _testHoldings);

    // Holdings' company names are generated as "<symbol> Ltd" (capitalised).
    // Searching lowercase partial should still match.
    await tester.enterText(find.byType(TextField), 'infy');
    await tester.pumpAndSettle();

    expect(find.text('INFY'), findsWidgets);
    expect(find.text('TCS'), findsNothing);
  });

  // Group 5: Combined filters -------------------------------------------------

  testWidgets('T18 Profit + Auto sector combined', (tester) async {
    await _pump(tester, _testHoldings);

    await tester.tap(find.text('Profit'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sector').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto').last);
    await tester.pumpAndSettle();

    // Only TMCV is profitable in Auto.
    expect(find.text('TMCV'), findsWidgets);
    expect(find.text('APAT'), findsNothing);
    expect(find.text('TCS'), findsNothing);
  });

  testWidgets('T19 four-dimensional filter intersects correctly',
      (tester) async {
    await _pump(tester, _testHoldings);

    await tester.tap(find.text('Profit'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sector').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('IT').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Industry'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Software').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'TCS');
    await tester.pumpAndSettle();

    // Only TCS matches all four conditions.
    expect(find.text('TCS'), findsWidgets);
    expect(find.text('INFY'), findsNothing);
    expect(find.text('TMCV'), findsNothing);
  });

  // Group 6: Reset ------------------------------------------------------------

  testWidgets('T20 Reset clears all filters and restores full list',
      (tester) async {
    await _pump(tester, _testHoldings);

    // Apply several filters.
    await tester.tap(find.text('Loss'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'AP');
    await tester.pumpAndSettle();

    // Confirm filtered.
    expect(find.text('TCS'), findsNothing);

    // Reset.
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    // All 5 holdings visible.
    expect(find.text('TCS'), findsWidgets);
    expect(find.text('INFY'), findsWidgets);
    expect(find.text('TMCV'), findsWidgets);
    expect(find.text('APAT'), findsWidgets);
    expect(find.text('HCLTECH'), findsWidgets);
    // Search field cleared.
    final tf = tester.widget<TextField>(find.byType(TextField));
    expect(tf.controller?.text, isEmpty);
  });

  testWidgets('T21 Reset does NOT clear sort column', (tester) async {
    await _pump(tester, _testHoldings);

    // Sort by column 7 (P&L) via the table header.
    await tester.tap(find.text('P&L'));
    await tester.pumpAndSettle();

    // Apply a filter then reset.
    await tester.tap(find.text('Profit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    // All holdings back; the sort icon should still show active sort.
    expect(find.byIcon(Icons.arrow_upward), findsWidgets);
  });

  // Group 7: Page reset -------------------------------------------------------

  testWidgets('T22 pagination total updates after status filter change',
      (tester) async {
    await _pump(tester, _testHoldings);
    expect(find.textContaining('of 5'), findsOneWidget);

    await tester.tap(find.text('Profit'));
    await tester.pumpAndSettle();

    expect(find.textContaining('of 3'), findsOneWidget);
    expect(find.textContaining('of 5'), findsNothing);
  });

  // Group 8: Responsive layout ------------------------------------------------

  testWidgets('T23 desktop layout — no RenderFlex overflow at 1400px',
      (tester) async {
    await _pump(tester, _testHoldings, surfaceSize: const Size(1400, 900));
    // If any overflow errors were thrown, pumpAndSettle would surface them.
    // Finding the single-row controls confirms desktop layout was used.
    expect(find.text('Sector'), findsWidgets);
    expect(find.text('Industry'), findsOneWidget);
    // No overflow exceptions thrown by the test framework.
  });

  testWidgets('T24 narrow layout — no RenderFlex overflow at 380px',
      (tester) async {
    await _pump(tester, _testHoldings, surfaceSize: const Size(380, 800));
    // Status + reset always visible; Sector/Industry sit in a scroll strip.
    expect(find.text('All'), findsWidgets);
    expect(find.text('Reset'), findsOneWidget);
    expect(find.text('Sector'), findsWidgets);
  });

  // Group 9: Edge cases -------------------------------------------------------

  testWidgets('T25 empty holdings renders empty state widget', (tester) async {
    await _pump(tester, const []);
    expect(find.text('No holdings found'), findsOneWidget);
  });

  testWidgets('T26 loading state renders progress indicator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdvancedHoldingsTemplate(holdings: [], isLoading: true),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  // Group 10: initialSector deep-link filtering (e.g. from Heatmap) ----------

  testWidgets('T27 initialSector pre-filters holdings on initial load',
      (tester) async {
    await _pump(tester, _testHoldings, initialSector: 'IT');
    // TCS, INFY, HCLTECH are in IT; TMCV, APAT (Auto) should be hidden
    expect(find.text('TCS'), findsWidgets);
    expect(find.text('INFY'), findsWidgets);
    expect(find.text('HCLTECH'), findsWidgets);
    expect(find.text('TMCV'), findsNothing);
    expect(find.text('APAT'), findsNothing);
    expect(find.textContaining('of 3'), findsOneWidget);
  });

  testWidgets('T28 initialSector displays pre-selected sector in dropdown',
      (tester) async {
    await _pump(tester, _testHoldings, initialSector: 'IT');
    expect(find.text('IT'), findsWidgets);
    // Closed trigger shows IT, not the "All Sectors" menu label.
    expect(find.text('All Sectors'), findsNothing);
  });

  testWidgets('T29 Reset button clears initialSector back to All',
      (tester) async {
    await _pump(tester, _testHoldings, initialSector: 'IT');
    expect(find.textContaining('of 3'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.textContaining('of 5'), findsOneWidget);
    expect(find.text('TMCV'), findsWidgets);
    expect(find.text('APAT'), findsWidgets);
    // Placeholder "Sector" returns (filter chip + column header).
    expect(find.text('Sector'), findsWidgets);
  });
}
