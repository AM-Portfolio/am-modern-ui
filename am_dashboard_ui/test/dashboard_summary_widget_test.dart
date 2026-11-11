import 'package:am_dashboard_ui/domain/models/dashboard_summary.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_summary_widget.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ThemeData _theme() {
  return ThemeData.dark().copyWith(
    extensions: const <ThemeExtension<dynamic>>[AppColorsTheme.dark],
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required DashboardSummary summary,
  double width = 400,
}) async {
  tester.view.physicalSize = Size(width + 80, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(size: Size(width + 80, 900)),
      child: MaterialApp(
        theme: _theme(),
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: DashboardSummaryWidget(summary: summary),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('cost-basis unknown shows Holdings and 1D Price Change',
      (tester) async {
    await _pump(
      tester,
      summary: const DashboardSummary(
        totalValue: 1268102,
        totalInvested: 0,
        totalGainLoss: 0,
        totalGainLossPercentage: 0,
        dayChange: 31288,
        dayChangePercentage: 10.17,
        totalPortfolios: 5,
        totalHoldings: 24,
      ),
    );

    expect(find.text('Total Portfolio Value'), findsOneWidget);
    expect(find.text('Total Holdings'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);
    expect(find.text('Securities in Portfolio'), findsOneWidget);
    expect(find.text('1D Price Change'), findsOneWidget);
    expect(find.textContaining('31,288'), findsOneWidget);
    expect(find.text('+10.17%'), findsOneWidget);
    expect(find.text('Active Portfolios'), findsOneWidget);
    expect(find.text('Total Invested'), findsNothing);
    expect(find.text('Total Return'), findsNothing);
    expect(find.text('Not in CAS (market value)'), findsNothing);
    expect(find.byIcon(Icons.account_balance_wallet_rounded), findsNothing);
    expect(find.byIcon(Icons.layers_rounded), findsNothing);
    expect(find.byIcon(Icons.bar_chart_rounded), findsNothing);
    expect(find.byIcon(Icons.layers_outlined), findsNothing);
  });

  testWidgets('wide layout keeps KPI icons', (tester) async {
    await _pump(
      tester,
      width: 1200,
      summary: const DashboardSummary(
        totalValue: 1268102,
        totalInvested: 0,
        totalGainLoss: 0,
        totalGainLossPercentage: 0,
        dayChange: 31288,
        dayChangePercentage: 10.17,
        totalPortfolios: 5,
        totalHoldings: 24,
      ),
    );

    expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);
    expect(find.byIcon(Icons.layers_rounded), findsOneWidget);
    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
    expect(find.byIcon(Icons.layers_outlined), findsOneWidget);
  });

  testWidgets('known cost basis keeps Invested and Return', (tester) async {
    await _pump(
      tester,
      summary: const DashboardSummary(
        totalValue: 100000,
        totalInvested: 80000,
        totalGainLoss: 20000,
        totalGainLossPercentage: 25,
        dayChange: 100,
        dayChangePercentage: 0.1,
        totalPortfolios: 2,
        totalHoldings: 10,
      ),
    );

    expect(find.text('Total Invested'), findsOneWidget);
    expect(find.text('Total Return'), findsOneWidget);
    expect(find.text('Total Holdings'), findsNothing);
    expect(find.text('1D Price Change'), findsNothing);
    expect(find.text('Principal Capital'), findsOneWidget);
  });
}
