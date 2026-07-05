import 'package:flutter/material.dart';
import 'package:am_design_system/core/utils/responsive_helper.dart';
import '../mobile/dashboard_mobile_screen.dart';
import '../web/dashboard_web_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String userId;

  const DashboardScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Standard breakpoint for tablet/web (1024px)
        if (constraints.maxWidth < ResponsiveHelper.tabletBreakpoint) {
          return DashboardMobileScreen(userId: userId);
        } else {
          return DashboardWebScreen(userId: userId);
        }
      },
    );
  }
}
