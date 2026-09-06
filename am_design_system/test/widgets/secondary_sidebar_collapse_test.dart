import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> setDesktop(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('secondary sidebar collapses to icons and leaves body offset',
      (tester) async {
    await setDesktop(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: UnifiedSidebarScaffold(
          title: 'Portfolio',
          items: [
            SecondarySidebarItem(
              title: 'Holdings',
              icon: Icons.pie_chart_outline,
              onTap: () {},
            ),
          ],
          body: const Text('BODY'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Holdings'), findsOneWidget);
    expect(find.text('BODY'), findsOneWidget);
    expect(find.byTooltip('Collapse sidebar'), findsOneWidget);

    await tester.tap(find.byTooltip('Collapse sidebar'));
    await tester.pumpAndSettle();

    expect(find.text('Holdings'), findsNothing);
    expect(find.byTooltip('Holdings'), findsOneWidget);
    expect(find.byTooltip('Expand sidebar'), findsOneWidget);
    expect(find.text('BODY'), findsOneWidget);
  });
}
