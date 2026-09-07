import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:am_design_system/am_design_system.dart';

void main() {
  Future<void> setViewport(WidgetTester tester, double width) async {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget buildTestApp() {
    return const MaterialApp(
      home: Scaffold(
        body: AmAdaptiveLayout(
          primary: Text('PRIMARY_SLOT'),
          secondary: Text('SECONDARY_SLOT'),
          detail: Text('DETAIL_SLOT'),
          watch: Text('WATCH_SLOT'),
        ),
      ),
    );
  }

  testWidgets('Watch (<200px): renders WATCH_SLOT only', (tester) async {
    await setViewport(tester, 160);
    await tester.pumpWidget(buildTestApp());

    expect(find.text('WATCH_SLOT'), findsOneWidget);
    expect(find.text('PRIMARY_SLOT'), findsNothing);
  });

  testWidgets('Mobile (<600px): renders single column with all slots',
      (tester) async {
    await setViewport(tester, 400);
    await tester.pumpWidget(buildTestApp());

    expect(find.text('PRIMARY_SLOT'), findsOneWidget);
    expect(find.text('SECONDARY_SLOT'), findsOneWidget);
    expect(find.text('DETAIL_SLOT'), findsOneWidget);

    // Mobile stacks all in a single Column, no Row layout
    expect(find.byType(Row), findsNothing);
  });

  testWidgets('Tablet (600px - 1099px): renders 2-column Row layout',
      (tester) async {
    await setViewport(tester, 800);
    await tester.pumpWidget(buildTestApp());

    expect(find.text('PRIMARY_SLOT'), findsOneWidget);
    expect(find.text('SECONDARY_SLOT'), findsOneWidget);
    expect(find.text('DETAIL_SLOT'), findsOneWidget);

    // Tablet uses Row layout
    expect(find.byType(Row), findsOneWidget);
  });

  testWidgets('Desktop (>=1100px): renders 3-column layout', (tester) async {
    await setViewport(tester, 1400);
    await tester.pumpWidget(buildTestApp());

    expect(find.text('PRIMARY_SLOT'), findsOneWidget);
    expect(find.text('SECONDARY_SLOT'), findsOneWidget);
    expect(find.text('DETAIL_SLOT'), findsOneWidget);

    expect(find.byType(Row), findsOneWidget);
  });

  testWidgets(
      'Zoom-compensated MediaQuery 1400px stays desktop even if box is 900',
      (tester) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(1400, 800)),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              child: AmAdaptiveLayout(
                primary: Text('PRIMARY_SLOT'),
                secondary: Text('SECONDARY_SLOT'),
                detail: Text('DETAIL_SLOT'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('PRIMARY_SLOT'), findsOneWidget);
    expect(find.text('SECONDARY_SLOT'), findsOneWidget);
    expect(find.text('DETAIL_SLOT'), findsOneWidget);
    expect(find.byType(Row), findsOneWidget);
  });
}
