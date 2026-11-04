import 'package:am_design_system/am_design_system.dart';
import 'package:am_trade_ui/features/trade/presentation/holdings/components/trade_holdings_advanced_template.dart';
import 'package:am_trade_ui/features/trade/presentation/models/trade_holding_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'price headers stay distinct when entry cost is known',
    (tester) async {
      tester.view.physicalSize = const Size(720, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              extensions: const [
                AppColorsTheme.light,
              ],
            ),
            home: Scaffold(
              body: SizedBox(
                width: 720,
                height: 500,
                child: TradeHoldingsAdvancedTemplate(
                  holdings: const [
                    TradeHoldingViewModel(
                      tradeId: 't1',
                      portfolioId: 'p1',
                      symbol: '10048NFL26-F',
                      companyName: '10048NFL26-F Corp.',
                      status: 'OPEN',
                      quantity: 1,
                      entryPrice: 100,
                      currentPrice: 90,
                      currentValue: 90,
                      profitLoss: -10,
                      profitLossPercentage: -10,
                      todayProfitLoss: -2,
                      todayProfitLossPercentage: -2.2,
                    ),
                  ],
                  isLoading: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Entry Price'), findsOneWidget);
      expect(find.text('Current Price'), findsOneWidget);
      expect(find.text('Current Value'), findsOneWidget);
      expect(find.text('1D P&L'), findsOneWidget);
      expect(find.text('Overall P&L'), findsOneWidget);

      final entry = tester.getRect(find.text('Entry Price'));
      final current = tester.getRect(find.text('Current Price'));
      final value = tester.getRect(find.text('Current Value'));
      final day = tester.getRect(find.text('1D P&L'));
      expect(entry.right <= current.left + 0.5, isTrue);
      expect(current.right <= value.left + 0.5, isTrue);
      expect(day.left - value.right, greaterThanOrEqualTo(8));
    },
  );

  testWidgets(
    'hides Entry Price column when all holdings lack cost',
    (tester) async {
      tester.view.physicalSize = const Size(720, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData(
              extensions: const [
                AppColorsTheme.light,
              ],
            ),
            home: Scaffold(
              body: SizedBox(
                width: 720,
                height: 500,
                child: TradeHoldingsAdvancedTemplate(
                  holdings: const [
                    TradeHoldingViewModel(
                      tradeId: 't1',
                      portfolioId: 'p1',
                      symbol: 'TATACONSUM',
                      companyName: 'Tata Consumer',
                      status: 'OPEN',
                      quantity: 5,
                      currentPrice: 1073,
                      currentValue: 5365,
                      todayProfitLoss: 220.5,
                      todayProfitLossPercentage: 4.29,
                    ),
                  ],
                  isLoading: false,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Entry Price'), findsNothing);
      expect(find.text('1D P&L'), findsOneWidget);
      expect(find.text('Overall P&L'), findsOneWidget);
      expect(find.text('Current Price'), findsOneWidget);
    },
  );
}
