/// Types of metrics for investment analysis
enum MetricType {
  /// Change percentage
  changePercent,
  
  /// Market value
  marketValue,
  
  /// Trading volume
  volume,
  averageVolume,
  
  /// Returns
  returns,
  
  dailyReturns,
  weeklyReturns,
  monthlyReturns,
  
  /// Return on Investment
  roi,
  
  investedValue,
  profitLoss,
  allocationPercent,
  
  /// Compound Annual Growth Rate
  cagr,
  
  /// Sharpe Ratio
  sharpeRatio,
  
  /// Maximum Drawdown
  maxDrawdown,
  drawdown,
  valueAtRisk,
  
  /// Volatility
  volatility,
  
  /// Alpha
  alpha,
  
  /// Beta
  beta,
  
  /// All metrics
  all;

  // ── Static list getters (used by selector widgets) ───────────────────────

  static List<MetricType> get portfolioMetrics => const [
        MetricType.marketValue,
        MetricType.profitLoss,
        MetricType.changePercent,
        MetricType.returns,
        MetricType.allocationPercent,
      ];

  static List<MetricType> get heatmapMetrics => const [
        MetricType.changePercent,
        MetricType.returns,
        MetricType.marketValue,
        MetricType.allocationPercent,
        MetricType.profitLoss,
      ];

  static List<MetricType> get mobileMetrics => const [
        MetricType.changePercent,
        MetricType.marketValue,
        MetricType.returns,
        MetricType.volume,
      ];

  static List<MetricType> get webMetrics => const [
        MetricType.changePercent,
        MetricType.marketValue,
        MetricType.returns,
        MetricType.volume,
        MetricType.volatility,
        MetricType.sharpeRatio,
        MetricType.beta,
        MetricType.profitLoss,
        MetricType.allocationPercent,
        MetricType.averageVolume,
        MetricType.valueAtRisk,
        MetricType.drawdown,
      ];

  static List<MetricType> get performanceMetrics => const [
        MetricType.returns,
        MetricType.dailyReturns,
        MetricType.weeklyReturns,
        MetricType.monthlyReturns,
        MetricType.changePercent,
      ];

  static List<MetricType> get riskMetrics => const [
        MetricType.volatility,
        MetricType.beta,
        MetricType.sharpeRatio,
        MetricType.drawdown,
        MetricType.valueAtRisk,
      ];

  static List<MetricType> get tradingMetrics => const [
        MetricType.changePercent,
        MetricType.volume,
        MetricType.averageVolume,
        MetricType.volatility,
      ];
}

/// Extension methods for MetricType
extension MetricTypeExtension on MetricType {
  /// Get display name for the metric type
  String get displayName {
    switch (this) {
      case MetricType.changePercent:
        return 'Change %';
      case MetricType.marketValue:
        return 'Market Value';
      case MetricType.volume:
        return 'Volume';
      case MetricType.averageVolume:
        return 'Avg Volume';
      case MetricType.returns:
        return 'Returns';
      case MetricType.dailyReturns:
        return 'Daily Returns';
      case MetricType.weeklyReturns:
        return 'Weekly Returns';
      case MetricType.monthlyReturns:
        return 'Monthly Returns';
      case MetricType.roi:
        return 'ROI';
      case MetricType.investedValue:
        return 'Invested Value';
      case MetricType.profitLoss:
        return 'Profit/Loss';
      case MetricType.allocationPercent:
        return 'Allocation %';
      case MetricType.cagr:
        return 'CAGR';
      case MetricType.sharpeRatio:
        return 'Sharpe Ratio';
      case MetricType.maxDrawdown:
        return 'Max Drawdown';
      case MetricType.drawdown:
        return 'Drawdown';
      case MetricType.valueAtRisk:
        return 'VaR';
      case MetricType.volatility:
        return 'Volatility';
      case MetricType.alpha:
        return 'Alpha';
      case MetricType.beta:
        return 'Beta';
      case MetricType.all:
        return 'All Metrics';
    }
  }

  /// Short name for compact display
  String get shortName {
    switch (this) {
      case MetricType.changePercent: return 'Change %';
      case MetricType.marketValue: return 'Value';
      case MetricType.volume: return 'Volume';
      case MetricType.averageVolume: return 'Avg Vol';
      case MetricType.returns: return 'Returns';
      case MetricType.dailyReturns: return 'Daily';
      case MetricType.weeklyReturns: return 'Weekly';
      case MetricType.monthlyReturns: return 'Monthly';
      case MetricType.roi: return 'ROI';
      case MetricType.investedValue: return 'Invested';
      case MetricType.profitLoss: return 'P&L';
      case MetricType.allocationPercent: return 'Alloc %';
      case MetricType.cagr: return 'CAGR';
      case MetricType.sharpeRatio: return 'Sharpe';
      case MetricType.maxDrawdown: return 'Max DD';
      case MetricType.drawdown: return 'Drawdown';
      case MetricType.valueAtRisk: return 'VaR';
      case MetricType.volatility: return 'Volatility';
      case MetricType.alpha: return 'Alpha';
      case MetricType.beta: return 'Beta';
      case MetricType.all: return 'All';
    }
  }
}
