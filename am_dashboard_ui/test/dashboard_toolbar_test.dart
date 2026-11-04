import 'dart:io';

import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/widgets/dashboard_portfolio_selector.dart';
import 'package:am_dashboard_ui/presentation/widgets/dashboard_toolbar.dart';
import 'package:am_dashboard_ui/presentation/widgets/paper_trading_nav_chip.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;

ThemeData _theme() {
  return ThemeData.dark().copyWith(
    extensions: const <ThemeExtension<dynamic>>[AppColorsTheme.dark],
  );
}

List<Override> _toolbarOverrides({String userId = 'test-user'}) => [
      dashboardPortfolioChoicesProvider.overrideWith((ref) async => const []),
      accountsHubProvider(userId).overrideWith(
        (ref) async => const AccountsHub(),
      ),
    ];

Future<void> _pumpToolbar(
  WidgetTester tester, {
  required Size size,
  VoidCallback? onSearch,
  VoidCallback? onPaper,
  ValueChanged<GlobalAddActionKind>? onQuickAdd,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  var paperTaps = 0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: _toolbarOverrides(),
      child: MaterialApp(
        theme: _theme(),
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            child: DashboardToolbar(
              userId: 'test-user',
              onSearch: onSearch ?? () {},
              onOpenPaper: onPaper ?? () => paperTaps++,
              onQuickAdd: onQuickAdd ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('390 toolbar order is search, paper, timeframe, overflow',
      (tester) async {
    var paperTaps = 0;
    var searchTaps = 0;
    await _pumpToolbar(
      tester,
      size: const Size(390, 844),
      onSearch: () => searchTaps++,
      onPaper: () => paperTaps++,
    );

    final search = tester.getRect(find.byIcon(Icons.search_rounded));
    final paper = tester.getRect(find.byKey(const Key('dashboard-paper-chip')));
    final tf = tester.getRect(find.byType(GlobalTimeFrameBar));
    final overflow = tester.getRect(find.byIcon(Icons.add_rounded));

    expect(search.left, lessThan(paper.left));
    expect(paper.left, lessThan(tf.left));
    expect(tf.left, lessThan(overflow.left));
    // Narrow widths keep the short Paper label; wide uses "Paper Trading".
    expect(
      find.text('Paper').evaluate().isNotEmpty ||
          find.text('Paper Trading').evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.byIcon(Icons.add_rounded), findsWidgets);

    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.tap(find.byKey(const Key('dashboard-paper-chip')));
    expect(searchTaps, 1);
    expect(paperTaps, 1);

    await tester.tap(find.byType(SyncQuickActionsControl));
    await tester.pumpAndSettle();
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Upload Portfolio'), findsOneWidget);
    expect(find.text('Add Trade'), findsOneWidget);
    expect(find.text('Add Asset Class'), findsOneWidget);
    expect(find.text('Add Basket'), findsOneWidget);
  });

  testWidgets('360 shows Paper segment and keeps timeframe visible',
      (tester) async {
    await _pumpToolbar(tester, size: const Size(360, 800));
    expect(
      find.text('Paper').evaluate().isNotEmpty ||
          find.text('Paper Trading').evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.text('Try'), findsNothing);
    expect(find.byKey(const Key('dashboard-toolbar-timeframe')), findsOneWidget);
    expect(find.byType(GlobalTimeFrameBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('800 trailing cluster keeps paper left of timeframe',
      (tester) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: _toolbarOverrides(),
        child: MaterialApp(
          theme: _theme(),
          home: Scaffold(
            body: Row(
              children: [
                const Text('Dashboard'),
                const SizedBox(width: 12),
                Expanded(
                  child: DashboardToolbar(
                    userId: 'test-user',
                    glass: false,
                    onOpenPaper: () {},
                    onQuickAdd: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final paper = tester.getRect(find.byKey(const Key('dashboard-paper-chip')));
    final tf = tester.getRect(find.byType(GlobalTimeFrameBar));
    expect(paper.left, lessThan(tf.left));
    expect(find.byIcon(Icons.search_rounded), findsNothing);
  });

  test('toolbar sources ban hardcoded chrome', () {
    const files = [
      'lib/presentation/widgets/paper_trading_nav_chip.dart',
      'lib/presentation/widgets/dashboard_toolbar.dart',
    ];
    const banned = [
      r'Color(0x',
      'Color.fromRGBO',
      'Color.fromARGB',
      'fontSize: 10',
      'fontSize: 12',
      'fontSize: 16',
    ];
    for (final rel in files) {
      final file = File(rel);
      expect(file.existsSync(), isTrue, reason: 'missing $rel');
      final src = file.readAsStringSync();
      for (final token in banned) {
        expect(
          src.contains(token),
          isFalse,
          reason: '$rel contains banned token `$token`',
        );
      }
    }
  });

  testWidgets('paper chip tap fires once', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: _theme(),
        home: Scaffold(
          body: PaperTradingNavChip(onTap: () => taps++),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('dashboard-paper-chip')));
    expect(taps, 1);
  });

  testWidgets('timeframe dropdown writes appTimeFrameProvider', (tester) async {
    late WidgetRef containerRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: _toolbarOverrides(),
        child: MaterialApp(
          theme: _theme(),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                containerRef = ref;
                return DashboardToolbar(
                  userId: 'test-user',
                  onSearch: () {},
                  onOpenPaper: () {},
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(containerRef.read(appTimeFrameProvider), TimeFrame.oneDay);

    await tester.tap(find.text('1D'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1W').last);
    await tester.pumpAndSettle();
    expect(containerRef.read(appTimeFrameProvider), TimeFrame.oneWeek);
  });

  testWidgets('412 stays one line without overflow', (tester) async {
    await _pumpToolbar(tester, size: const Size(412, 844));
    expect(tester.takeException(), isNull);
    expect(
      find.text('Paper').evaluate().isNotEmpty ||
          find.text('Paper Trading').evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.byType(DashboardToolbar), findsOneWidget);
  });

  testWidgets('wide toolbar shows Paper Trading and Advanced', (tester) async {
    var advancedTaps = 0;
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: _toolbarOverrides(),
        child: MaterialApp(
          theme: _theme(),
          home: Scaffold(
            body: DashboardToolbar(
              userId: 'test-user',
              glass: false,
              onOpenPaper: () {},
              onOpenUsers: () => advancedTaps++,
              onQuickAdd: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Paper Trading'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dashboard-advanced-chip')));
    expect(advancedTaps, 1);
  });
}
