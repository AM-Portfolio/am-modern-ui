import 'dart:io';

import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/f_o/presentation/widgets/fo_header_card.dart';
import 'package:am_market_ui/features/f_o/providers/futures_provider.dart';
import 'package:am_market_ui/features/f_o/providers/option_chain_provider.dart';
import 'package:am_market_ui/features/watchlists/data/models/watchlist_model.dart';
import 'package:am_market_ui/features/watchlists/providers/watchlist_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as legacy_provider;

ThemeData _theme({AppColorsTheme palette = AppColorsTheme.dark}) {
  return ThemeData.dark().copyWith(
    extensions: <ThemeExtension<dynamic>>[
      palette,
      MarketThemeExtension.dark(),
    ],
  );
}

Map<String, dynamic> _chain({
  bool withMetrics = true,
  bool withChange = true,
}) {
  return {
    'underlyingLtp': 22811.35,
    if (withChange) 'underlyingChange': -150.20,
    if (withChange) 'underlyingPChange': -0.66,
    'exchange': 'NSE',
    if (withMetrics) 'lotSize': 65,
    if (withMetrics)
      'strikes': [
        {
          'call': {
            'oi': 100,
            'lotSize': 65,
            'greeks': {'iv': 0.29},
          },
          'put': {
            'oi': 70,
            'greeks': {'iv': 0.29},
          },
        },
      ],
  };
}

_foOverrides({
  Map<String, dynamic>? chain,
  List<dynamic> contracts = const [],
}) {
  return [
    optionChainProvider.overrideWith((ref) async => chain),
    futuresContractsProvider.overrideWith((ref) async => contracts),
    marketIsOpenProvider.overrideWith((ref) => Stream<bool>.value(false)),
    marketStatusProvider.overrideWith(
      (ref) => const MarketStatus(
        exchange: 'NSE',
        open: false,
        reason: 'OUTSIDE_SESSION',
      ),
    ),
    watchlistCheckStatusProvider.overrideWith((ref, symbol) async {
      return const <WatchlistCheckStatus>[];
    }),
  ];
}

Future<MarketProvider> _marketWithSpark() async {
  final market = MarketProvider();
  market.debugHistoryBatchFetcher = (symbols, range) async {
    return {
      for (final s in symbols)
        s: [
          {'close': 23200.0},
          {'close': 23000.0},
          {'close': 22811.35},
        ],
    };
  };
  await market.ensureIndexSparklines(['NIFTY 50']);
  return market;
}

BoxDecoration _headerGlass(WidgetTester tester) {
  final containers = tester.widgetList<Container>(
    find.descendant(
      of: find.byType(GlassCard),
      matching: find.byType(Container),
    ),
  );
  for (final container in containers) {
    final decoration = container.decoration;
    if (decoration is BoxDecoration && decoration.gradient != null) {
      return decoration;
    }
  }
  fail('GlassCard has no gradient decoration');
}

Future<void> _pumpHeader(
  WidgetTester tester, {
  required Size size,
  Map<String, dynamic>? chain,
  List<dynamic> contracts = const [],
  MarketProvider? market,
  String symbol = 'NIFTY',
  ThemeData? theme,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  Widget body = ProviderScope(
    overrides: _foOverrides(chain: chain, contracts: contracts),
    child: MaterialApp(
      theme: theme ?? _theme(),
      home: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: FoHeaderCard(
            symbol: symbol,
          ),
        ),
      ),
    ),
  );
  if (market != null) {
    body = legacy_provider.ChangeNotifierProvider<MarketProvider>.value(
      value: market,
      child: body,
    );
  }

  await tester.pumpWidget(body);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('FoHeaderCard geometry', () {
    testWidgets('desktop places chart right of LTP with live metrics',
        (tester) async {
      final market = await _marketWithSpark();
      await _pumpHeader(
        tester,
        size: const Size(1100, 800),
        chain: _chain(),
        market: market,
      );

      expect(find.text('NIFTY 50'), findsOneWidget);
      expect(find.text('NSE'), findsOneWidget);
      expect(find.text('FUT'), findsOneWidget);
      expect(find.text('INDEX'), findsNothing);
      expect(find.text('Lot Size'), findsOneWidget);
      expect(find.text('IV'), findsOneWidget);
      expect(find.text('PCR (OI)'), findsOneWidget);
      expect(find.text('Market Status'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      expect(find.byIcon(Icons.show_chart), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.text('₹22,811.35'), findsOneWidget);
      expect(find.textContaining('22,811'), findsWidgets);
      expect(find.textContaining('-150.20'), findsOneWidget);
      expect(find.text('65'), findsOneWidget);
      expect(find.text('29.0%'), findsOneWidget);
      expect(find.text('0.70'), findsOneWidget);
      expect(find.textContaining('—'), findsNothing);
      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);

      final chart = tester.getRect(find.byKey(const Key('fo-header-chart')));
      expect(chart.width, greaterThanOrEqualTo(160));
      final ltp = tester.getRect(find.text('₹22,811.35'));
      expect(chart.left, greaterThan(ltp.right));
    });

    testWidgets('mobile chart is not a 48x22 title-row sparkline',
        (tester) async {
      final market = await _marketWithSpark();
      await _pumpHeader(
        tester,
        size: const Size(390, 844),
        chain: _chain(),
        market: market,
      );

      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
      expect(find.text('493.4%'), findsNothing);
      expect(find.text('0.54'), findsNothing);

      final chart = tester.getRect(find.byKey(const Key('fo-header-chart')));
      expect(chart.width, greaterThanOrEqualTo(96));
      expect(chart.height, greaterThan(22));
      final ltp = tester.getRect(find.text('₹22,811.35'));
      expect(chart.height, greaterThan(22));
      expect(chart.left, greaterThan(ltp.right));
      expect(chart.bottom, greaterThanOrEqualTo(ltp.bottom - 8));

      final pcr = tester.getRect(find.byKey(const Key('fo-metric-pcr')));
      final status = tester.getRect(find.byKey(const Key('fo-metric-status')));
      expect(pcr.overlaps(status), isFalse);
    });

    testWidgets('empty chain shows em dash not fake fallbacks', (tester) async {
      await _pumpHeader(
        tester,
        size: const Size(390, 844),
        chain: const {},
      );
      expect(find.text('493.4%'), findsNothing);
      expect(find.text('0.54'), findsNothing);
      expect(find.text('Lot Size'), findsOneWidget);
      expect(find.text('IV'), findsOneWidget);
      expect(find.text('PCR (OI)'), findsOneWidget);
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('empty sparkline keeps inset without RNG series', (tester) async {
      await _pumpHeader(
        tester,
        size: const Size(1100, 800),
        chain: _chain(),
      );
      expect(find.byKey(const Key('fo-header-chart')), findsOneWidget);
      expect(find.byType(AmSparklineChart), findsNothing);
    });

    testWidgets('BANKNIFTY title is fully visible NIFTY BANK at 390',
        (tester) async {
      await _pumpHeader(
        tester,
        size: const Size(390, 844),
        chain: _chain(),
        symbol: 'BANKNIFTY',
      );

      expect(find.text('NIFTY BANK'), findsOneWidget);
      expect(find.text('BANKNIFTY'), findsNothing);
      final paragraph =
          tester.renderObject<RenderParagraph>(find.text('NIFTY BANK'));
      expect(paragraph.didExceedMaxLines, isFalse);

      expect(find.text('Closed'), findsOneWidget);
      expect(find.textContaining('OUTSIDE_SESSION'), findsNothing);
      final tooltip = tester.widget<Tooltip>(
        find.descendant(
          of: find.byKey(const Key('fo-metric-status')),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, 'OUTSIDE_SESSION');
    });

    testWidgets('header glass follows Imperial Gold cardSurface', (tester) async {
      const palette = AppColorsTheme.imperialGold;
      await _pumpHeader(
        tester,
        size: const Size(390, 844),
        chain: _chain(),
        symbol: 'NIFTY',
        theme: _theme(palette: palette),
      );

      final gradient = _headerGlass(tester).gradient! as LinearGradient;
      expect(
        gradient.colors.first,
        palette.cardSurface.withValues(alpha: GlassCard.themedFillAlphaDark[0]),
      );
      expect(
        _headerGlass(tester).border?.top.color,
        palette.border,
      );
    });

    test('embed path in fo_page.dart does not build FoHeaderCard', () {
      final src = File('lib/features/f_o/presentation/pages/fo_page.dart')
          .readAsStringSync();
      final embedFn = src.split('_buildEmbedDetailView')[1].split('Widget ')[0];
      expect(embedFn.contains('FoHeaderCard'), isFalse);
    });
  });
}
