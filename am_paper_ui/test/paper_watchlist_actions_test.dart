import 'package:am_design_system/am_design_system.dart';
import 'package:am_paper_ui/data/watchlist_models.dart';
import 'package:am_paper_ui/presentation/widgets/watchlist/common/watchlist_atoms.dart';
import 'package:am_paper_ui/presentation/widgets/watchlist/watchlist_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ThemeData testTheme() {
    return ThemeData.dark().copyWith(
      extensions: const <ThemeExtension<dynamic>>[
        AppColorsTheme.dark,
      ],
    );
  }

  group('Paper Trading Watchlist Actions', () {
    testWidgets('WatchlistActionToolbar triggers onAddToWatchlist when bookmark icon is tapped', (tester) async {
      bool added = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme(),
          home: Scaffold(
            body: WatchlistActionToolbar(
              onBuy: () {},
              onSell: () {},
              onFundamentals: () {},
              onAddToWatchlist: () {
                added = true;
              },
            ),
          ),
        ),
      );

      final bookmarkFinder = find.byIcon(Icons.bookmark_add_outlined);
      expect(bookmarkFinder, findsOneWidget);

      await tester.tap(bookmarkFinder);
      await tester.pump();

      expect(added, isTrue);
    });

    testWidgets('WatchlistRow passes onAddToWatchlist through toolbar', (tester) async {
      bool added = false;
      const stock = WatchlistStock(
        symbol: 'TRENT',
        name: 'Trent Limited',
        exchange: 'NSE',
        ltp: 3079.0,
        change: 24.0,
        changePercent: 0.79,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme(),
          home: Scaffold(
            body: WatchlistRow(
              stock: stock,
              selected: false,
              showActions: true,
              depthExpanded: false,
              enableHover: false,
              onHover: (_) {},
              onTap: () {},
              onBuy: () {},
              onSell: () {},
              onFundamentals: () {},
              onAddToWatchlist: () {
                added = true;
              },
              onRemove: () {},
            ),
          ),
        ),
      );

      final bookmarkFinder = find.byIcon(Icons.bookmark_add_outlined);
      expect(bookmarkFinder, findsOneWidget);

      await tester.tap(bookmarkFinder);
      await tester.pump();

      expect(added, isTrue);
    });

    testWidgets('WatchlistSourceDropdown exposes Create New Watchlist item', (tester) async {
      bool createTriggered = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: testTheme(),
          home: Scaffold(
            body: Center(
              child: WatchlistSourceDropdown(
                selected: const WatchlistSource(id: 'nifty-50', name: 'Nifty 50'),
                sources: const [
                  WatchlistSource(id: 'nifty-50', name: 'Nifty 50'),
                ],
                onSelected: (_) {},
                onCreateWatchlist: () {
                  createTriggered = true;
                },
              ),
            ),
          ),
        ),
      );

      // Tap dropdown trigger
      await tester.tap(find.text('Nifty 50'));
      await tester.pumpAndSettle();

      final createItemFinder = find.text('Create New Watchlist…');
      expect(createItemFinder, findsOneWidget);

      await tester.tap(createItemFinder);
      await tester.pumpAndSettle();

      expect(createTriggered, isTrue);
    });
  });
}
