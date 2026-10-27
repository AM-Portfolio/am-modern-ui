import 'package:am_design_system/am_design_system.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_holding.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_summary.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/overview_metric_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PortfolioHolding _holding({
  required String symbol,
  required double investedAmount,
  required double avgPrice,
}) {
  return PortfolioHolding(
    id: symbol,
    symbol: symbol,
    name: symbol,
    companyName: symbol,
    sector: 'IT',
    industry: 'Software',
    quantity: 10,
    avgPrice: avgPrice,
    currentPrice: 100,
    investedAmount: investedAmount,
    currentValue: 1000,
    todayChange: 12,
    todayChangePercentage: 1,
    totalGainLoss: investedAmount > 0 ? 100 : 0,
    totalGainLossPercentage: 0,
    portfolioWeight: 10,
  );
}

PortfolioSummary _summary({double invested = 0, double gain = 0}) {
  return PortfolioSummary.empty().copyWith(
    totalValue: 2438376.41,
    investmentValue: invested,
    totalGainLoss: gain,
    totalGainLossPercentage: invested > 0 ? 4.5 : 0,
    todayChange: 12577.67,
    todayChangePercentage: 0.52,
    totalAssets: 86,
    priceFreshness: 'LIVE',
  );
}

ThemeData _theme() => ThemeData.dark().copyWith(
      extensions: const <ThemeExtension<dynamic>>[AppColorsTheme.dark],
    );

Future<void> _pump(
  WidgetTester tester, {
  required List<PortfolioHolding> holdings,
  required PortfolioSummary summary,
  required double width,
  bool isPhone = false,
}) async {
  await tester.binding.setSurfaceSize(Size(width, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: _theme(),
      home: Scaffold(
        body: SizedBox(
          width: width,
          child: OverviewMetricStrip(
            summary: summary,
            holdings: holdings,
            isPhone: isPhone,
            compact: isPhone,
            glowBorder: !isPhone,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Dhan-style overview hides Total Return and Invested Amount',
      (tester) async {
    await _pump(
      tester,
      width: 960,
      summary: _summary(),
      holdings: [
        _holding(symbol: 'SWIGGY', investedAmount: 0, avgPrice: 0),
      ],
    );

    expect(find.text('Total Return'), findsNothing);
    expect(find.text('Invested Amount'), findsNothing);
    expect(find.text("Today's P&L"), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);

    final today = tester.getTopLeft(find.text("Today's P&L"));
    final balance = tester.getTopLeft(find.text('Total Balance'));
    expect((today.dy - balance.dy).abs(), lessThan(8));
    expect(balance.dx, greaterThan(today.dx));
  });

  testWidgets('cost-basis overview keeps Total Return and Invested Amount',
      (tester) async {
    await _pump(
      tester,
      width: 960,
      summary: _summary(invested: 50000, gain: 1200),
      holdings: [
        _holding(symbol: 'TCS', investedAmount: 50000, avgPrice: 250),
      ],
    );

    expect(find.text('Total Return'), findsOneWidget);
    expect(find.text('Invested Amount'), findsOneWidget);
    expect(find.text("Today's P&L"), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);
  });

  testWidgets('summary principal keeps four cards even if rows lack cost',
      (tester) async {
    await _pump(
      tester,
      width: 960,
      summary: _summary(invested: 863000, gain: 12000),
      holdings: [
        _holding(symbol: 'TCS', investedAmount: 0, avgPrice: 0),
      ],
    );

    expect(find.text('Total Return'), findsOneWidget);
    expect(find.text('Invested Amount'), findsOneWidget);
  });

  testWidgets('empty holdings keep four cards until mail cost is known',
      (tester) async {
    await _pump(
      tester,
      width: 960,
      summary: _summary(invested: 863000, gain: 12000),
      holdings: const [],
    );

    expect(find.text('Total Return'), findsOneWidget);
    expect(find.text('Invested Amount'), findsOneWidget);
    expect(find.text("Today's P&L"), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);
  });

  testWidgets('phone Dhan strip is a single two-card row', (tester) async {
    await _pump(
      tester,
      width: 360,
      isPhone: true,
      summary: _summary(),
      holdings: [
        _holding(symbol: 'IDEA', investedAmount: 0, avgPrice: 0),
      ],
    );

    expect(find.text('Total Return'), findsNothing);
    expect(find.text('Invested Amount'), findsNothing);
    expect(find.text("Today's P&L"), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);
    final today = tester.getTopLeft(find.text("Today's P&L"));
    final balance = tester.getTopLeft(find.text('Total Balance'));
    expect((today.dy - balance.dy).abs(), lessThan(8));
  });
}
