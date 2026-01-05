import 'package:flutter/material.dart';

import '../../selectors/selectors.dart';
import '../configs/display_config.dart';
import '../configs/layout_config.dart' as layout_config;
import '../configs/selector_config.dart';
import '../heatmap_config.dart' as ui_config;
import 'types.dart';

/// Universal heatmap configuration manager
/// Provides basic configuration for universal heatmap system
class UniversalHeatmapConfigManager {
  /// Gets basic configuration - simple fallback when no config is provided
  static ui_config.HeatmapConfig getBasicConfig({
    String? title,
    bool compactMode = false,
  }) => ui_config.HeatmapConfig(
    display: const DisplayConfig(),
    layout: layout_config.LayoutConfig(
      compactView: compactMode,
      customTitle: title,
    ),
    selectors: const SelectorConfig(),
  );

  // Basic initial values for selectors
  static TimeFrame getInitialTimeFrame(InvestmentType investmentType) =>
      TimeFrame.oneYear;
  static MetricType getInitialMetric(InvestmentType investmentType) =>
      MetricType.returns;
  static SectorType getInitialSector(InvestmentType investmentType) =>
      SectorType.all;
  static MarketCapType getInitialMarketCap(InvestmentType investmentType) =>
      MarketCapType.all;

  // Basic default titles
  static String getDefaultTitle(InvestmentType investmentType) {
    switch (investmentType) {
      case InvestmentType.portfolio:
        return 'Portfolio';
      case InvestmentType.indexFund:
        return 'Index Fund';
      case InvestmentType.mutualFunds:
        return 'Mutual Funds';
      case InvestmentType.etf:
        return 'ETF';
    }
  }

  static String getDefaultSubtitle(InvestmentType investmentType) {
    switch (investmentType) {
      case InvestmentType.portfolio:
        return 'Portfolio Overview';
      case InvestmentType.indexFund:
        return 'Index Performance';
      case InvestmentType.mutualFunds:
        return 'Fund Performance';
      case InvestmentType.etf:
        return 'ETF Performance';
    }
  }

  static IconData getInvestmentIcon(InvestmentType investmentType) {
    switch (investmentType) {
      case InvestmentType.portfolio:
        return Icons.pie_chart;
      case InvestmentType.indexFund:
        return Icons.trending_up;
      case InvestmentType.mutualFunds:
        return Icons.account_balance;
      case InvestmentType.etf:
        return Icons.show_chart;
    }
  }
}
