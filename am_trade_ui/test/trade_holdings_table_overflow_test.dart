import 'package:am_design_system/am_design_system.dart';
import 'package:am_trade_ui/features/trade/presentation/holdings/components/trade_holdings_advanced_template.dart';
import 'package:am_trade_ui/features/trade/presentation/models/trade_holding_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'price headers stay distinct on a narrow viewport',
    (tester) async {
      tester.view.physicalSize = const Size(720, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
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
                    entryPrice: 0,
                    currentPrice: 0,
                    currentValue: 0,
                    profitLoss: -13615,
                    profitLossPercentage: -100,
                  ),
                ],
                isLoading: false,
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

      final entry = tester.getRect(find.text('Entry Price'));
      final current = tester.getRect(find.text('Current Price'));
      final value = tester.getRect(find.text('Current Value'));
      final pnl = tester.getRect(find.text('P&L'));
      expect(entry.right <= current.left + 0.5, isTrue);
      expect(current.right <= value.left + 0.5, isTrue);
      expect(pnl.left - value.right, greaterThanOrEqualTo(8));
    },
  );
}
