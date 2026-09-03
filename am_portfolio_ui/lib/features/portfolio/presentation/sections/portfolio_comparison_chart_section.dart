import 'package:am_auth_ui/am_auth_ui.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_overlay_provider.dart';
import 'package:am_dashboard_ui/presentation/shared/widgets/dashboard_chart_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dashboard-style overlay comparison chart (Overall vs indices) for Portfolio overview.
class PortfolioComparisonChartSection extends ConsumerWidget {
  const PortfolioComparisonChartSection({
    super.key,
    required this.height,
    this.userId,
  });

  final double height;
  final String? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedUserId = userId ?? _userIdFromAuth(context);
    if (resolvedUserId.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Sign in to view performance chart')),
      );
    }

    ref.watch(dashboardOverlayProvider(resolvedUserId));

    return SizedBox(
      height: height,
      child: DashboardChartWidget(userId: resolvedUserId),
    );
  }

  String _userIdFromAuth(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    if (authState is Authenticated) return authState.user.id;
    return '';
  }
}
