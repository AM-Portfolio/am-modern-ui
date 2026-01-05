import '../../charts/chart_types.dart';

/// Configuration for portfolio overview display
class PortfolioOverviewConfig {
  const PortfolioOverviewConfig({
    this.showSummary = true,
    this.showMovers = true,
    this.showAllocation = true,
    this.showCharts = true,
    this.defaultChartType = ChartType.donut,
    this.defaultAllocationType = AllocationType.sector,
    this.enableExport = true,
    this.enableRefresh = true,
  });

  final bool showSummary;
  final bool showMovers;
  final bool showAllocation;
  final bool showCharts;
  final ChartType defaultChartType;
  final AllocationType defaultAllocationType;
  final bool enableExport;
  final bool enableRefresh;

  /// Web preset with all features enabled
  factory PortfolioOverviewConfig.web() => const PortfolioOverviewConfig(
        showSummary: true,
        showMovers: true,
        showAllocation: true,
        showCharts: true,
        enableExport: true,
        enableRefresh: true,
      );

  /// Mobile preset with simplified features
  factory PortfolioOverviewConfig.mobile() => const PortfolioOverviewConfig(
        showSummary: true,
        showMovers: true,
        showAllocation: true,
        showCharts: true,
        defaultChartType: ChartType.pie,
        enableExport: false,
        enableRefresh: true,
      );

  /// Minimal preset for dashboard widgets
  factory PortfolioOverviewConfig.minimal() => const PortfolioOverviewConfig(
        showSummary: true,
        showMovers: false,
        showAllocation: false,
        showCharts: false,
        enableExport: false,
        enableRefresh: false,
      );
}



enum AllocationType {
  sector,
  marketCap,
}
