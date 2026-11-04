import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> setMobile(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 815);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('mobile pill tabs can be tapped and trigger callbacks',
      (tester) async {
    await setMobile(tester);
    int selectedIndex = 2; // Heatmap selected
    final tappedIndices = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return UnifiedSidebarScaffold(
              title: 'Portfolio',
              autoHideMobileTabsOnScroll: true,
              items: [
                SecondarySidebarItem(
                  title: 'Overview',
                  icon: Icons.dashboard_outlined,
                  isSelected: selectedIndex == 0,
                  onTap: () {
                    tappedIndices.add(0);
                    setState(() => selectedIndex = 0);
                  },
                ),
                SecondarySidebarItem(
                  title: 'Holdings',
                  icon: Icons.wallet,
                  isSelected: selectedIndex == 1,
                  onTap: () {
                    tappedIndices.add(1);
                    setState(() => selectedIndex = 1);
                  },
                ),
                SecondarySidebarItem(
                  title: 'Heatmap',
                  icon: Icons.grid_view,
                  isSelected: selectedIndex == 2,
                  onTap: () {
                    tappedIndices.add(2);
                    setState(() => selectedIndex = 2);
                  },
                ),
                SecondarySidebarItem(
                  title: 'Baskets',
                  icon: Icons.shopping_basket_outlined,
                  isSelected: selectedIndex == 3,
                  onTap: () {
                    tappedIndices.add(3);
                    setState(() => selectedIndex = 3);
                  },
                ),
              ],
              body: ListView.builder(
                itemCount: 50,
                itemBuilder: (context, index) =>
                    ListTile(title: Text('Item $index')),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Holdings'), findsOneWidget);
    expect(find.text('Heatmap'), findsOneWidget);
    expect(find.text('Baskets'), findsOneWidget);

    // Tap Overview
    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();

    expect(tappedIndices, contains(0));
    expect(selectedIndex, 0);

    // Tap Holdings
    await tester.tap(find.text('Holdings'));
    await tester.pumpAndSettle();

    expect(tappedIndices, contains(1));
    expect(selectedIndex, 1);
  });

  testWidgets('mobile pill tabs behavior during and after vertical scroll',
      (tester) async {
    await setMobile(tester);
    int selectedIndex = 0;
    final tappedIndices = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return UnifiedSidebarScaffold(
              title: 'Portfolio',
              autoHideMobileTabsOnScroll: true,
              items: [
                SecondarySidebarItem(
                  title: 'Overview',
                  icon: Icons.dashboard_outlined,
                  isSelected: selectedIndex == 0,
                  onTap: () {
                    tappedIndices.add(0);
                    setState(() => selectedIndex = 0);
                  },
                ),
                SecondarySidebarItem(
                  title: 'Holdings',
                  icon: Icons.wallet,
                  isSelected: selectedIndex == 1,
                  onTap: () {
                    tappedIndices.add(1);
                    setState(() => selectedIndex = 1);
                  },
                ),
              ],
              body: ListView.builder(
                itemCount: 50,
                itemBuilder: (context, index) =>
                    ListTile(title: Text('Item $index')),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down 100 pixels
    await tester.drag(find.text('Item 2'), const Offset(0, -100));
    await tester.pumpAndSettle();

    // Now scroll back up to 0
    await tester.drag(find.text('Item 5'), const Offset(0, 200));
    await tester.pumpAndSettle();

    // Verify tabs are visible and clickable again
    expect(find.text('Holdings'), findsOneWidget);
    await tester.tap(find.text('Holdings'));
    await tester.pumpAndSettle();

    expect(tappedIndices, contains(1));
  });
}
