import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/futures_contract_mobile_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AmBreakpoints F&O mobile tier', () {
    test('phone widths are below mobile cutoff', () {
      for (final width in [360.0, 375.0, 390.0, 430.0]) {
        expect(width < AmBreakpoints.mobile, isTrue);
      }
    });

    test('tablet band keeps compact table range', () {
      expect(600.0 >= AmBreakpoints.mobile, isTrue);
      expect(1099.0 < AmBreakpoints.tablet, isTrue);
      expect(1100.0 >= AmBreakpoints.tablet, isTrue);
    });
  });

  group('FuturesContractMobileTile', () {
    testWidgets('renders contract, LTP, change, OI and volume', (tester) async {
      final theme = ThemeData.dark().copyWith(
        extensions: <ThemeExtension<dynamic>>[
          AppColorsTheme.dark,
          MarketThemeExtension.dark(),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: FuturesContractMobileTile(
              tradingSymbol: 'NIFTY26SEPFUT',
              expiryLabel: '24 Sep 2026',
              ltp: 24850.5,
              change: 12.25,
              pChange: 0.05,
              oi: 1250000,
              volume: 98000,
              isSelected: true,
              formatNum: (n) => n.toString(),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('NIFTY26SEPFUT'), findsOneWidget);
      expect(find.text('24 Sep 2026'), findsOneWidget);
      expect(find.textContaining('24850.50'), findsOneWidget);
      expect(find.textContaining('OI'), findsOneWidget);
      expect(find.textContaining('Vol'), findsOneWidget);
    });
  });
}
