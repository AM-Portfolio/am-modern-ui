import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

NavigationItem _item(String title, Color color) {
  return NavigationItem(
    title: title,
    subtitle: title,
    icon: Icons.circle,
    accentColor: color,
    page: Center(child: Text(title)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SwipeNavigationController rapid navigateTo', () {
    testWidgets(
      'rapid navigateTo leaves final index and clears programmatic flag',
      (tester) async {
        final controller = SwipeNavigationController(
          items: [
            _item('A', Colors.red),
            _item('B', Colors.green),
            _item('C', Colors.blue),
            _item('D', Colors.orange),
            _item('E', Colors.purple),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeablePageView(
                controller: controller,
                showIndicator: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Mix: adjacent animate (old hang path) then jumps (sidebar default).
        controller.navigateTo(1, animate: true);
        controller.navigateTo(2, animate: true);
        controller.navigateTo(3);
        controller.navigateTo(4);

        await tester.pumpAndSettle();

        expect(controller.currentIndex, 4);
        expect(controller.isProgrammaticNavigation, isFalse);
        expect(controller.pageController.page?.round(), 4);

        controller.dispose();
      },
    );

    testWidgets(
      're-tap recovers when page is desynced from currentIndex',
      (tester) async {
        final controller = SwipeNavigationController(
          items: [
            _item('A', Colors.red),
            _item('B', Colors.green),
            _item('C', Colors.blue),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeablePageView(
                controller: controller,
                showIndicator: false,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        controller.navigateTo(2, animate: false);
        await tester.pumpAndSettle();
        expect(controller.currentIndex, 2);

        // Force a desync: page left behind while index already advanced.
        controller.pageController.jumpToPage(0);
        await tester.pump();

        // Same index re-tap must still sync (recovery path).
        controller.navigateTo(2, animate: false);
        await tester.pumpAndSettle();

        expect(controller.currentIndex, 2);
        expect(controller.pageController.page?.round(), 2);
        expect(controller.isProgrammaticNavigation, isFalse);

        controller.dispose();
      },
    );
  });
}
