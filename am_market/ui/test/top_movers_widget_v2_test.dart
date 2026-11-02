import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/models/top_mover_stock.dart';
import 'package:am_market_ui/features/dashboard/presentation/widgets/top_movers_widget_v2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('market adapter forwards the selected mover symbol',
      (tester) async {
    final selected = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SizedBox(
            width: 760,
            height: 520,
            child: TopMoversWidgetV2(
              gainers: [
                TopMoverStock(
                  symbol: ' tatatest ',
                  companyName: 'Tata Test',
                  lastPrice: 100,
                  change: 5,
                  changePercent: 5,
                  volume: 1000,
                ),
              ],
              losers: [
                TopMoverStock(
                  symbol: 'ONCGTEST',
                  companyName: 'ONCG Test',
                  lastPrice: 200,
                  change: -2,
                  changePercent: -2,
                  volume: 1000,
                ),
              ],
              onSymbolTap: selected.add,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text(' tatatest '));
    await tester.tap(find.text('ONCGTEST'));

    expect(selected, [' tatatest ', 'ONCGTEST']);
  });
}
