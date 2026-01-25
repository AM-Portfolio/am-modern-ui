/// Types of metrics for investment analysis
enum MetricType {
  /// Change percentage
  changePercent,
  
  /// Market value
  marketValue,
  
  /// Trading volume
  volume,
  
  /// Returns
  returns,
  
  /// Return on Investment
  roi,
  
  /// Compound Annual Growth Rate
  cagr,
  
  /// Sharpe Ratio
  sharpeRatio,
  
  /// Maximum Drawdown
  maxDrawdown,
  
  /// Volatility
  volatility,
  
  /// Alpha
  alpha,
  
  /// Beta
  beta,
  
  /// All metrics
  all,
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
      case MetricType.returns:
        return 'Returns';
      case MetricType.roi:
        return 'ROI';
      case MetricType.cagr:
        return 'CAGR';
      case MetricType.sharpeRatio:
        return 'Sharpe Ratio';
      case MetricType.maxDrawdown:
        return 'Max Drawdown';
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
}
