import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('top mover activation emits both gainer and loser items',
      (tester) async {
    final tapped = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SizedBox(
            width: 760,
            height: 520,
            child: AmTopMoversPanel(
              gainers: const [
                AmMoverItem(
                  symbol: 'TATATEST',
                  price: 100,
                  priceLabel: '₹100.00',
                  changePercent: 5,
                ),
              ],
              losers: const [
                AmMoverItem(
                  symbol: 'ONCGTEST',
                  price: 200,
                  priceLabel: '₹200.00',
                  changePercent: -2,
                ),
              ],
              onItemTap: (item) => tapped.add(item.symbol),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('TATATEST'));
    await tester.tap(find.text('ONCGTEST'));

    expect(tapped, ['TATATEST', 'ONCGTEST']);
  });

  testWidgets('top mover remains display-only without a callback',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SizedBox(
            width: 760,
            height: 520,
            child: AmTopMoversPanel(
              gainers: const [
                AmMoverItem(
                  symbol: 'TATATEST',
                  price: 100,
                  priceLabel: '₹100.00',
                  changePercent: 5,
                ),
              ],
              losers: const [],
            ),
          ),
        ),
      ),
    );

  });
}
