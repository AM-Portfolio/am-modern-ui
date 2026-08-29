import 'package:flutter/widgets.dart';

/// Context passed to catalog builders when rendering a dashboard slot.
class DashboardWidgetContext {
  const DashboardWidgetContext({
    required this.userId,
    required this.timeFrameCode,
    this.onOpenDocIntel,
    this.chartHeight,
  });

  final String userId;
  final String timeFrameCode;
  final VoidCallback? onOpenDocIntel;
  final double? chartHeight;
}

/// Identifiers for dashboard widget slots sourced from feature modules.
enum DashboardWidgetId {
  summary,
  portfolioWealthChart,
  movers,
  recentActivity,
  portfolioList,
  allocation,
  benchmarkComparison,
}

extension DashboardWidgetIdX on DashboardWidgetId {
  String get label => switch (this) {
        DashboardWidgetId.summary => 'Summary',
        DashboardWidgetId.portfolioWealthChart => 'Portfolio Chart',
        DashboardWidgetId.movers => 'Top Movers',
        DashboardWidgetId.recentActivity => 'Recent Activity',
        DashboardWidgetId.portfolioList => 'Your Portfolios',
        DashboardWidgetId.allocation => 'Allocation',
        DashboardWidgetId.benchmarkComparison => 'Performance Chart',
      };

  String get module => switch (this) {
        DashboardWidgetId.portfolioWealthChart ||
        DashboardWidgetId.allocation =>
          'portfolio',
        DashboardWidgetId.benchmarkComparison => 'market',
        _ => 'dashboard',
      };

  static DashboardWidgetId? tryParse(String raw) {
    for (final id in DashboardWidgetId.values) {
      if (id.name == raw) return id;
    }
    return null;
  }
}

enum DashboardWidgetSize {
  full,
  twoThirds,
  oneThird,
  half,
}
