import 'package:flutter/material.dart';
import '../mobile/dashboard_mobile_screen.dart';
import '../web/dashboard_web_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String userId;

  const DashboardScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Standard breakpoint for tablet/web
        if (constraints.maxWidth < 1100) {
          return DashboardMobileScreen(userId: userId);
        } else {
          return DashboardWebScreen(userId: userId);
        }
      },
    );
  }
}
