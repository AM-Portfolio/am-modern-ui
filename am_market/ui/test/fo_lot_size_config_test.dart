import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/f_o/fo_lot_size_config.dart';
import 'package:am_market_ui/features/f_o/presentation/pages/margin_calculator_view.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/futures_contract_details_card.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/futures_contracts_table_widget.dart';
import 'package:am_market_ui/features/f_o/providers/fo_provider.dart';
import 'package:am_market_ui/features/f_o/providers/futures_provider.dart';
import 'package:am_market_ui/features/f_o/providers/option_chain_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestSymbolNotifier extends FoActiveSymbolNotifier {
  _TestSymbolNotifier(this.symbol);
  final String symbol;
  @override
  String? build() => symbol;
}

Widget _wrapWithApp(Widget child, {List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: MaterialApp(
      theme: ThemeData.dark().copyWith(
        extensions: <ThemeExtension<dynamic>>[
          AppColorsTheme.dark,
          MarketThemeExtension.dark(),
        ],
      ),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('FoLotSizeConfig Unit Tests', () {
    test('Formats numeric expiry strings as user-facing dates', () {
      expect(
        FuturesContractDetailsCard.formatExpiry(
          {'expiry': '1800901799000'},
        ),
        '25 Jan 2027',
      );
    });

    test('Prefers the formatted expiry supplied with the contract', () {
      expect(
        FuturesContractDetailsCard.formatExpiry(
          {'expiry': '1800901799000', 'expiry_display': '25 Jan 2027'},
        ),
        '25 Jan 2027',
      );
    });

    test('Expired futures are not restored when no active contract exists', () {
      final now = DateTime(2026, 11, 11).millisecondsSinceEpoch;
      final contracts = filterActiveFutureContracts(
        [
          {'trading_symbol': 'NIFTY25JANFUT', 'expiry': now - 86400000 * 60},
          {'trading_symbol': 'NIFTY26DEC FUT', 'expiry': now + 86400000 * 20},
        ],
        nowMs: now,
      );

      expect(contracts, hasLength(1));
      expect(contracts.single['trading_symbol'], 'NIFTY26DEC FUT');
    });

    test('Default exchange lot sizes for NSE indices match 2026 mandates', () {
      expect(FoLotSizeConfig.resolveLotSize(symbol: 'NIFTY'), 65);
      expect(FoLotSizeConfig.resolveLotSize(symbol: 'NIFTY 50'), 65);
      expect(FoLotSizeConfig.resolveLotSize(symbol: 'BANKNIFTY'), 30);
      expect(FoLotSizeConfig.resolveLotSize(symbol: 'NIFTY BANK'), 30);
      expect(FoLotSizeConfig.resolveLotSize(symbol: 'FINNIFTY'), 60);
      expect(FoLotSizeConfig.resolveLotSize(symbol: 'NIFTY FINANCIAL SERVICES'),
          60);
      expect(FoLotSizeConfig.resolveLotSize(symbol: 'NIFTY FIN SERVICE'), 60);
      expect(FoLotSizeConfig.resolveLotSize(symbol: 'MIDCPNIFTY'), 120);
      expect(
          FoLotSizeConfig.resolveLotSize(symbol: 'NIFTY MIDCAP SELECT'), 120);
      expect(FoLotSizeConfig.resolveLotSize(symbol: 'NIFTYNXT50'), 25);
      expect(FoLotSizeConfig.resolveLotSize(symbol: 'NIFTY NEXT 50'), 25);
    });

    test('Default exchange lot sizes for BSE indices match 2026 mandates', () {
      expect(FoLotSizeConfig.resolveLotSize(symbol: 'SENSEX'), 20);
      expect(FoLotSizeConfig.resolveLotSize(symbol: 'BSE SENSEX'), 20);
      expect(FoLotSizeConfig.resolveLotSize(symbol: 'BANKEX'), 30);
      expect(FoLotSizeConfig.resolveLotSize(symbol: 'BSE BANKEX'), 30);
      expect(FoLotSizeConfig.resolveLotSize(symbol: 'SENSEX50'), 75);
      expect(FoLotSizeConfig.resolveLotSize(symbol: 'BSE SENSEX 50'), 75);
    });

    test(
        'Dynamic contract API response takes priority for stock underliers (e.g., TCS)',
        () {
      // Unloaded TCS defaults to 1
      expect(FoLotSizeConfig.resolveLotSize(symbol: 'TCS'), 1);

      // Loaded TCS contract response with lot_size: 225
      final contract = {
        'trading_symbol': 'TCS26MAYFUT',
        'lot_size': 225,
        'ltp': 3450.0,
      };
      expect(
        FoLotSizeConfig.resolveLotSize(symbol: 'TCS', contract: contract),
        225,
      );
    });

    test('Resolves string and camelCase lotSize properties from API response',
        () {
      expect(
        FoLotSizeConfig.resolveLotSize(
          symbol: 'INFY',
          contract: {'lotSize': '400'},
        ),
        400,
      );
      expect(
        FoLotSizeConfig.resolveLotSize(
          symbol: 'RELIANCE',
          contract: {'minimum_lot_size': 250},
        ),
        250,
      );
    });

    test(
        'Resolves lot size from Option Chain root and strikes when contract is null',
        () {
      final chainRoot = {
        'lotSize': 175,
        'underlyingLtp': 1500.0,
      };
      expect(
        FoLotSizeConfig.resolveLotSize(symbol: 'CUSTOM', chainData: chainRoot),
        175,
      );

      final chainStrikes = {
        'strikes': [
          {
            'call': {'lotSize': 350},
          }
        ],
      };
      expect(
        FoLotSizeConfig.resolveLotSize(
            symbol: 'CUSTOM', chainData: chainStrikes),
        350,
      );
    });
  });

  group('MarginCalculatorView Active Dynamic Lot Size Binding Tests', () {
    testWidgets('Desktop margin panels render with confirmed contract data',
        (tester) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final contract = {
        'trading_symbol': 'TCS26MAYFUT',
        'lot_size': 225,
        'ltp': 3450.0,
      };
      await tester.pumpWidget(_wrapWithApp(
        const MarginCalculatorView(),
        overrides: [
          foActiveSymbolProvider.overrideWith(() => _TestSymbolNotifier('TCS')),
          futuresContractsMetadataProvider
              .overrideWith((ref) async => [contract]),
          selectedFutureQuoteProvider('TCS26MAYFUT')
              .overrideWith((ref) async => {'lastPrice': 3450.0}),
        ],
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Margin Required'), findsWidgets);
      expect(find.textContaining('3450.00'), findsWidgets);
    }, skip: !kIsWeb);

    testWidgets(
        'Automatically binds dynamic contract lot size when API response arrives',
        (tester) async {
      final tcsContract = {
        'trading_symbol': 'TCS26MAYFUT',
        'lot_size': 225,
        'ltp': 3450.0,
      };

      await tester.pumpWidget(
        _wrapWithApp(
          const MarginCalculatorView(),
          overrides: [
            foActiveSymbolProvider
                .overrideWith(() => _TestSymbolNotifier('TCS')),
            futuresContractsMetadataProvider
                .overrideWith((ref) async => [tcsContract]),
            optionChainProvider.overrideWith((ref) async => null),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // Quantity TextField should actively match the contract lot size (225)
      expect(find.text('225'), findsWidgets);
      // Read-only price display should actively match the contract LTP.
      expect(find.textContaining('3450.00'), findsWidgets);
    });

    testWidgets('Preserves user custom edit when widget rebuilds',
        (tester) async {
      final tcsContract = {
        'trading_symbol': 'TCS26MAYFUT',
        'lot_size': 225,
        'ltp': 3450.0,
      };

      await tester.pumpWidget(
        _wrapWithApp(
          const MarginCalculatorView(),
          overrides: [
            foActiveSymbolProvider
                .overrideWith(() => _TestSymbolNotifier('TCS')),
            futuresContractsMetadataProvider
                .overrideWith((ref) async => [tcsContract]),
            optionChainProvider.overrideWith((ref) async => null),
          ],
        ),
      );

      await tester.pumpAndSettle();

      // User enters custom quantity 450
      final qtyFinder = find.widgetWithText(TextField, '225').first;
      await tester.enterText(qtyFinder, '450');
      await tester.pumpAndSettle();

      expect(find.text('450'), findsWidgets);
    });
  });
}
