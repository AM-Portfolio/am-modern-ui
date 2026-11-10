import 'dart:io';

import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/domain/models/accounts_hub.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_chart_widget.dart';
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
        (ref) async => const AccountsHub(
          identity: AccountsIdentity(
            name: 'Priyanshu Kumar',
            email: 'priyanshu@example.com',
          ),
        ),
      ),
    ];

Future<void> _pumpToolbar(
  WidgetTester tester, {
  required Size size,
  VoidCallback? onSearch,
  VoidCallback? onPaper,
  VoidCallback? onProfile,
  ValueChanged<GlobalAddActionKind>? onQuickAdd,
  DateTime Function()? now,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
              onOpenPaper: onPaper ?? () {},
              onOpenUsers: () {},
              onProfileTap: onProfile,
              onQuickAdd: onQuickAdd ?? (_) {},
              now: now,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('390 mobile chrome greets by time and has no toolbar timeframe',
      (tester) async {
    var paperTaps = 0;
    var searchTaps = 0;
    var profileTaps = 0;
    await _pumpToolbar(
      tester,
      size: const Size(390, 844),
      onSearch: () => searchTaps++,
      onPaper: () => paperTaps++,
      onProfile: () => profileTaps++,
      now: () => DateTime(2026, 11, 10, 9),
    );

    expect(find.text('AM Investment'), findsNothing);
    expect(find.text('Good Morning'), findsOneWidget);
    expect(find.textContaining('Priyanshu'), findsNothing);
    expect(find.byKey(const Key('dashboard-toolbar-profile')), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);
    expect(find.byKey(const Key('dashboard-toolbar-timeframe')), findsNothing);
    expect(find.byType(GlobalTimeFrameBar), findsNothing);

    final search = tester.getRect(find.byIcon(Icons.search_rounded));
    final paper = tester.getRect(find.byKey(const Key('dashboard-paper-chip')));
    final overflow = tester.getRect(find.byIcon(Icons.add_rounded));

    expect(search.left, lessThan(paper.left));
    expect(find.text('Paper'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsWidgets);
    expect(overflow.top, greaterThan(paper.bottom - 8));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('dashboard-toolbar-profile')));
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.tap(find.byKey(const Key('dashboard-paper-chip')));
    expect(profileTaps, 1);
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

  testWidgets('360 shows Paper segment and no toolbar timeframe',
      (tester) async {
    await _pumpToolbar(tester, size: const Size(360, 800));
    expect(
      find.text('Paper').evaluate().isNotEmpty ||
          find.text('Paper Trading').evaluate().isNotEmpty,
      isTrue,
    );
    expect(find.text('Try'), findsNothing);
    expect(find.byKey(const Key('dashboard-toolbar-timeframe')), findsNothing);
    expect(find.byType(GlobalTimeFrameBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('800 trailing cluster keeps paper left of portfolio picker',
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
    final picker = tester.getRect(find.byType(DashboardPortfolioSelector));
    expect(paper.left, lessThan(picker.left));
    expect(find.byType(GlobalTimeFrameBar), findsNothing);
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

  testWidgets('chart timeframe dropdown writes appTimeFrameProvider',
      (tester) async {
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
                return SizedBox(
                  height: 320,
                  child: DashboardChartWidget(userId: 'test-user'),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('dashboard-chart-timeframe')), findsOneWidget);
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
