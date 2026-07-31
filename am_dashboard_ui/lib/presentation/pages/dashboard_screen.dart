import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../web/dashboard_web_screen.dart';
import '../mobile/dashboard_mobile_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String userId;
  final VoidCallback? onOpenDocIntel;

  const DashboardScreen({
    super.key,
    required this.userId,
    this.onOpenDocIntel,
  });

  @override
  Widget build(BuildContext context) {
    return AmBreakpoints.isMobileContext(context)
        ? DashboardMobileScreen(
            userId: userId,
            onOpenDocIntel: onOpenDocIntel,
          )
        : DashboardWebScreen(
            userId: userId,
            onOpenDocIntel: onOpenDocIntel,
          );
  }
}
