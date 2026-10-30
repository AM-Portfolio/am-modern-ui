import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/f_o/presentation/pages/option_chain_view.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/futures_contract_mobile_tile.dart';
import 'package:am_market_ui/features/f_o/providers/option_chain_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  testWidgets('mobile Option Chain centers Spot and shows full STRIKE values',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final strikes = List.generate(80, (index) {
      final strike = 21000 + index * 50;
      return <String, dynamic>{
        'strikePrice': strike,
        'call': <String, dynamic>{'ltp': 125.0, 'closePrice': 120.0},
        'put': <String, dynamic>{'ltp': 75.0, 'closePrice': 80.0},
      };
    });
    final theme = ThemeData.dark().copyWith(
      extensions: <ThemeExtension<dynamic>>[
        AppColorsTheme.dark,
        MarketThemeExtension.dark(),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          optionChainProvider.overrideWith((ref) async => <String, dynamic>{
                'underlyingLtp': 22654.85,
                'strikes': strikes,
                'expiry': '2026-10-27',
                'expiries': <String>['2026-10-27'],
              }),
        ],
        child: MaterialApp(
          theme: theme,
          home: const Scaffold(
            body: OptionChainView(showExpiryInToolbar: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final list = tester.widget<ListView>(find.byType(ListView));
    final position = list.controller!.position;
    const spotIndex = (22650 - 21000) ~/ 50;
    final expectedOffset =
        ((spotIndex + 1) * 44.0 - position.viewportDimension / 2)
            .clamp(0.0, position.maxScrollExtent);
    expect(position.pixels, closeTo(expectedOffset, 0.5));
    expect(find.text('22650'), findsOneWidget);
    expect(tester.getSize(find.text('22650')).height, greaterThan(10));
    expect(find.textContaining('Spot: ₹22654.85'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.textContaining('Spot: ₹22654.85'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, 500));
    await tester.pumpAndSettle();
    expect(find.textContaining('Spot: ₹22654.85'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
