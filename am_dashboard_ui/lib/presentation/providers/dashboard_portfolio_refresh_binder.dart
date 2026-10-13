import 'package:am_common/am_common.dart';
import 'package:am_dashboard_ui/presentation/providers/dashboard_provider.dart';
import 'package:am_dashboard_ui/presentation/providers/has_demo_portfolio_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Invalidates dashboard portfolio widgets when holdings are imported elsewhere.
class DashboardPortfolioRefreshBinder extends ConsumerStatefulWidget {
  const DashboardPortfolioRefreshBinder({
    super.key,
    required this.userId,
    required this.child,
  });

  final String userId;
  final Widget child;

  @override
  ConsumerState<DashboardPortfolioRefreshBinder> createState() =>
      _DashboardPortfolioRefreshBinderState();
}

class _DashboardPortfolioRefreshBinderState
    extends ConsumerState<DashboardPortfolioRefreshBinder> {
  @override
  void initState() {
    super.initState();
    PortfolioDataRefresh.instance.addListener(_onImported);
  }

  @override
  void dispose() {
    PortfolioDataRefresh.instance.removeListener(_onImported);
    super.dispose();
  }

  void _onImported() {
    if (!mounted) return;
    final id = widget.userId;
    if (id.isEmpty) return;
    ref.invalidate(portfolioOverviewsProvider(id));
    ref.invalidate(hasDemoPortfolioProvider);
    ref.invalidate(dashboardStreamProvider(id));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
