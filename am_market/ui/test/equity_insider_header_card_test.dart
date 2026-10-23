import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_sdk/market/api.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/equity_insider/presentation/widgets/equity_insider_header_card.dart';
import 'package:am_market_ui/features/equity_insider/presentation/widgets/equity_insider_hero.dart';
import 'package:am_market_ui/features/equity_insider/providers/equity_insider_provider.dart';
import 'package:am_market_ui/features/watchlists/data/models/watchlist_model.dart';
import 'package:am_market_ui/features/watchlists/providers/watchlist_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ThemeData _theme({AppColorsTheme palette = AppColorsTheme.dark}) {
  return ThemeData.dark().copyWith(
    extensions: <ThemeExtension<dynamic>>[
      palette,
      MarketThemeExtension.dark(),
    ],
  );
}

_overrides({
  double? price = 1209,
  double? change = 7,
  double? pct = 0.58,
}) {
  return [
    fundamentalProfileProvider.overrideWith((ref, query) async {
      return FundamentalRatiosResponse(
        symbol: 'RELIANCE',
        companyName: 'RELIANCE INDUSTRIES LTD',
        currentPrice: price,
        dayChange: change,
        dayChangePercent: pct,
      );
    }),
    watchlistCheckStatusProvider.overrideWith((ref, symbol) async {
      return const <WatchlistCheckStatus>[];
    }),
  ];
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

Future<ProviderContainer> _pumpHero(
  WidgetTester tester, {
  required Size size,
  overrides,
  ThemeData? theme,
}) async {
  final container = ProviderContainer(
    overrides: overrides ?? _overrides(),
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme ?? _theme(),
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: const EquityInsiderHeroBar(symbol: 'RELIANCE'),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return container;
}

void main() {
  group('EquityInsiderHeaderCard geometry', () {
    testWidgets('mobile 390 paints full name above LTP', (tester) async {
      await _pumpHero(tester, size: const Size(390, 844));

      expect(find.text('RELIANCE INDUSTRIES LTD'), findsOneWidget);
      expect(find.text('NSE'), findsOneWidget);
      expect(find.text('BSE'), findsOneWidget);
      expect(find.textContaining('₹'), findsOneWidget);
      expect(find.textContaining('+7.00'), findsOneWidget);
      expect(find.text('Add to Watchlist'), findsNothing);
      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
      expect(find.byType(VerticalDivider), findsNothing);

      final name = tester.getRect(find.byKey(const Key('ei-header-name')));
      final ltp = tester.getRect(find.textContaining('₹'));
      final nseChip = tester.getRect(find.widgetWithText(AmToggleChip, 'NSE'));
      expect(ltp.top, greaterThanOrEqualTo(name.bottom - 1));
      expect(nseChip.top - name.bottom, lessThan(AppSpacing.sm));

      // Flutter tests use a square-glyph font, so didExceedMaxLines is not a
      // real-font signal for a 24-char name at 390. Title width must still be
      // enough for RELIANCE INDUSTRIES LTD in a proportional face (~0.62em).
      expect(name.width, greaterThanOrEqualTo(220));
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byKey(const Key('ei-header-name')),
      );
      expect(paragraph.text.toPlainText(), 'RELIANCE INDUSTRIES LTD');

      final nse = tester.widget<AmToggleChip>(
        find.widgetWithText(AmToggleChip, 'NSE'),
      );
      expect(nse.accentColor, ModuleColors.market);
      expect(nse.selected, isTrue);

      final cardH = tester.getSize(find.byType(GlassCard)).height;
      // Pin padding is xs on each edge (page). Tight to the measured card.
      expect(
        EquityInsiderHeaderCard.mobileStickyPinExtent,
        greaterThanOrEqualTo(cardH + AppSpacing.xs * 2),
      );
      expect(
        EquityInsiderHeaderCard.mobileStickyPinExtent,
        lessThanOrEqualTo(cardH + AppSpacing.lg),
      );

      final nameWidget = tester.widget<Text>(
        find.text('RELIANCE INDUSTRIES LTD'),
      );
      expect(nameWidget.maxLines, 1);
      expect(nameWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('desktop 1100 keeps LTP right of name', (tester) async {
      await _pumpHero(tester, size: const Size(1100, 844));

      expect(find.text('RELIANCE INDUSTRIES LTD'), findsOneWidget);
      expect(find.text('NSE'), findsOneWidget);
      expect(find.text('BSE'), findsOneWidget);
      expect(find.textContaining('₹'), findsOneWidget);
      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
      expect(find.byType(VerticalDivider), findsNothing);

      final name = tester.getRect(find.text('RELIANCE INDUSTRIES LTD'));
      final ltp = tester.getRect(find.textContaining('₹'));
      expect(ltp.left, greaterThan(name.right));

      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('RELIANCE INDUSTRIES LTD'),
      );
      expect(paragraph.didExceedMaxLines, isFalse);
    });

    testWidgets('tapping BSE updates selectedExchangeProvider', (tester) async {
      final container = await _pumpHero(tester, size: const Size(390, 844));
      expect(container.read(selectedExchangeProvider), 'NSE');
      await tester.tap(find.widgetWithText(AmToggleChip, 'BSE'));
      await tester.pump();
      expect(container.read(selectedExchangeProvider), 'BSE');
    });

    testWidgets('header glass follows Imperial Gold cardSurface', (tester) async {
      const palette = AppColorsTheme.imperialGold;
      await _pumpHero(
        tester,
        size: const Size(390, 844),
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

    testWidgets('null price shows em dash and hides fake +0.00', (tester) async {
      await _pumpHero(
        tester,
        size: const Size(390, 844),
        overrides: _overrides(price: null, change: null, pct: null),
      );
      expect(find.text('—'), findsOneWidget);
      expect(find.textContaining('+0.00'), findsNothing);
      expect(find.textContaining('₹0.00'), findsNothing);
    });
  });
}
