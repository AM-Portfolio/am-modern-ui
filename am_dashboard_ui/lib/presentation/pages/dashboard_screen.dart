import 'package:am_dashboard_ui/presentation/layout/dashboard_layout_bootstrap.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../web/dashboard_web_screen.dart';
import '../mobile/dashboard_mobile_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final String userId;
  final VoidCallback? onOpenDocIntel;

  const DashboardScreen({
    super.key,
    required this.userId,
    this.onOpenDocIntel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(dashboardSessionUserIdProvider(userId));
    return sessionAsync.when(
      data: (resolvedUserId) => DashboardLayoutBootstrap(
        userId: resolvedUserId,
        child: AmBreakpoints.isMobileContext(context)
            ? DashboardMobileScreen(
                userId: resolvedUserId,
                onOpenDocIntel: onOpenDocIntel,
              )
            : DashboardWebScreen(
                userId: resolvedUserId,
                onOpenDocIntel: onOpenDocIntel,
              ),
      ),
      loading: () => const _DashboardSessionLoading(),
      error: (_, __) => const _DashboardSessionLoading(),
    );
  }
}

class _DashboardSessionLoading extends StatelessWidget {
  const _DashboardSessionLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
