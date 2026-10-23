import 'dart:io';

import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/presentation/widgets/dashboard_toolbar.dart';
import 'package:am_dashboard_ui/presentation/widgets/paper_trading_nav_chip.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

ThemeData _theme() {
  return ThemeData.dark().copyWith(
    extensions: const <ThemeExtension<dynamic>>[AppColorsTheme.dark],
  );
}

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
      child: MaterialApp(
        theme: _theme(),
        home: Scaffold(
          body: SizedBox(
            width: size.width,
            child: DashboardToolbar(
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
    final overflow = tester.getRect(find.byIcon(Icons.more_horiz));

    expect(search.left, lessThan(paper.left));
    expect(paper.left, lessThan(tf.left));
    expect(tf.left, lessThan(overflow.left));
    expect(paper.right, lessThanOrEqualTo(tf.left + 0.5));
    expect(find.text('Try'), findsOneWidget);

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

  testWidgets('360 hides Paper Trading label and does not overflow',
      (tester) async {
    await _pumpToolbar(tester, size: const Size(360, 800));
    expect(find.text('Paper Trading'), findsNothing);
    expect(find.text('Try'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
        child: MaterialApp(
          theme: _theme(),
          home: Scaffold(
            body: Row(
              children: [
                const Text('Dashboard'),
                const Spacer(),
                DashboardToolbar(
                  glass: false,
                  onOpenPaper: () {},
                  onQuickAdd: (_) {},
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
        child: MaterialApp(
          theme: _theme(),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                containerRef = ref;
                return DashboardToolbar(
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
    expect(find.text('Try'), findsOneWidget);
    expect(find.byType(DashboardToolbar), findsOneWidget);
  });
}
