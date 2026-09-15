import 'package:flutter/widgets.dart';

/// Context passed to catalog builders when rendering a dashboard slot.
class DashboardWidgetContext {
  const DashboardWidgetContext({
    required this.userId,
    required this.timeFrameCode,
    this.onOpenDocIntel,
    this.onOpenPaper,
    this.chartHeight,
  });

  final String userId;
  final String timeFrameCode;
  final VoidCallback? onOpenDocIntel;
  final VoidCallback? onOpenPaper;
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
  news,
  paperTrading,
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
        DashboardWidgetId.news => 'Market Intelligence',
        DashboardWidgetId.paperTrading => 'Paper trading',
      };

  String get module => switch (this) {
        DashboardWidgetId.portfolioWealthChart ||
        DashboardWidgetId.allocation =>
          'portfolio',
        DashboardWidgetId.benchmarkComparison => 'market',
        DashboardWidgetId.paperTrading => 'paper',
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
