import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('bottom nav has no Profile title or trailing profile control',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlobalBottomNavigation(
            activeNavItem: 'Dashboard',
            isDarkMode: true,
            onNavigate: (_) {},
            items: const [
              SidebarItem(title: 'Dashboard', icon: Icons.dashboard_rounded),
              SidebarItem(title: 'Trade', icon: Icons.swap_horiz_rounded),
              SidebarItem(title: 'Market', icon: Icons.show_chart_rounded),
              SidebarItem(title: 'AI Chat', icon: Icons.auto_awesome_rounded),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsNothing);
    expect(find.byKey(const Key('bottom-nav-profile')), findsNothing);
  });
}
