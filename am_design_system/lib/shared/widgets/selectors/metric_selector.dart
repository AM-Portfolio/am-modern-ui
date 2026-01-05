import 'package:flutter/material.dart';
import 'package:am_design_system/core/utils/common_logger.dart';


import '../inputs/app_segmented_control.dart';

/// Enum for different metric types that can be displayed
enum MetricType {
  // Performance metrics
  returns('Returns', 'Total Returns', Icons.trending_up),
  dailyReturns('Daily', 'Daily Returns', Icons.today),
  weeklyReturns('Weekly', 'Weekly Returns', Icons.date_range),
  monthlyReturns('Monthly', 'Monthly Returns', Icons.calendar_month),

  // Value metrics
  marketValue('Value', 'Market Value', Icons.account_balance_wallet),
  investedValue('Invested', 'Invested Value', Icons.payment),
  profitLoss('P&L', 'Profit & Loss', Icons.account_balance),

  // Percentage metrics
  changePercent('Change %', 'Change Percentage', Icons.percent),
  allocationPercent('Allocation %', 'Portfolio Allocation', Icons.pie_chart),

  // Performance ratios
  sharpeRatio('Sharpe', 'Sharpe Ratio', Icons.analytics),
  beta('Beta', 'Portfolio Beta', Icons.show_chart),
  volatility('Volatility', 'Price Volatility', Icons.waves),

  // Risk metrics
  drawdown('Drawdown', 'Maximum Drawdown', Icons.trending_down),
  valueAtRisk('VaR', 'Value at Risk', Icons.warning),

  // Volume metrics
  volume('Volume', 'Trading Volume', Icons.bar_chart),
  averageVolume('Avg Volume', 'Average Volume', Icons.timeline);

  const MetricType(this.shortName, this.displayName, this.icon);

  /// Short name for compact display
  final String shortName;

  /// Full display name
  final String displayName;

  /// Representative icon
  final IconData icon;

  /// Get metric type from short name
  static MetricType? fromShortName(String shortName) {
    for (final metric in MetricType.values) {
      if (metric.shortName == shortName) {
        return metric;
      }
    }
    return null;
  }

  /// Common metrics for portfolio overview
  static List<MetricType> get portfolioMetrics => [
    MetricType.marketValue,
    MetricType.profitLoss,
    MetricType.changePercent,
    MetricType.returns,
    MetricType.allocationPercent,
  ];

  /// Common metrics for performance analysis
  static List<MetricType> get performanceMetrics => [
    MetricType.returns,
    MetricType.dailyReturns,
    MetricType.weeklyReturns,
    MetricType.monthlyReturns,
    MetricType.changePercent,
  ];

  /// Common metrics for risk analysis
  static List<MetricType> get riskMetrics => [
    MetricType.volatility,
    MetricType.beta,
    MetricType.sharpeRatio,
    MetricType.drawdown,
    MetricType.valueAtRisk,
  ];

  /// Common metrics for heatmap display
  static List<MetricType> get heatmapMetrics => [
    MetricType.changePercent,
    MetricType.returns,
    MetricType.marketValue,
    MetricType.allocationPercent,
    MetricType.profitLoss,
  ];

  /// Common metrics for trading analysis
  static List<MetricType> get tradingMetrics => [
    MetricType.changePercent,
    MetricType.volume,
    MetricType.averageVolume,
    MetricType.volatility,
  ];

  /// Mobile-optimized metrics (limited selection)
  static List<MetricType> get mobileMetrics => [
    MetricType.changePercent,
    MetricType.marketValue,
    MetricType.returns,
    MetricType.volume,
  ];

  /// Web-optimized metrics (full selection)
  static List<MetricType> get webMetrics => [
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
}

/// Widget for selecting different metrics to display
class MetricSelector extends StatelessWidget {
  /// Constructor
  const MetricSelector({
    required this.selectedMetric,
    required this.onMetricChanged,
    super.key,
    this.availableMetrics,
    this.compact = false,
    this.primaryColor,
    this.showIcons = false,
    this.useDisplayNames = false,
    this.title,
    this.asDropdown = false,
  });

  /// Factory constructor for portfolio context
  factory MetricSelector.portfolio({
    required MetricType selectedMetric,
    required ValueChanged<MetricType> onMetricChanged,
    Key? key,
    bool compact = false,
    Color? primaryColor,
    bool showIcons = true,
    String? title,
  }) => MetricSelector(
    key: key,
    selectedMetric: selectedMetric,
    onMetricChanged: onMetricChanged,
    availableMetrics: MetricType.portfolioMetrics,
    compact: compact,
    primaryColor: primaryColor,
    showIcons: showIcons,
    title: title,
  );

  /// Factory constructor for performance analysis context
  factory MetricSelector.performance({
    required MetricType selectedMetric,
    required ValueChanged<MetricType> onMetricChanged,
    Key? key,
    bool compact = true,
    Color? primaryColor,
    String? title,
  }) => MetricSelector(
    key: key,
    selectedMetric: selectedMetric,
    onMetricChanged: onMetricChanged,
    availableMetrics: MetricType.performanceMetrics,
    compact: compact,
    primaryColor: primaryColor,
    title: title,
  );

  /// Factory constructor for risk analysis context
  factory MetricSelector.risk({
    required MetricType selectedMetric,
    required ValueChanged<MetricType> onMetricChanged,
    Key? key,
    bool asDropdown = true,
    Color? primaryColor,
    String? title,
  }) => MetricSelector(
    key: key,
    selectedMetric: selectedMetric,
    onMetricChanged: onMetricChanged,
    availableMetrics: MetricType.riskMetrics,
    asDropdown: asDropdown,
    primaryColor: primaryColor,
    useDisplayNames: true,
    title: title,
  );

  /// Factory constructor for heatmap context
  factory MetricSelector.heatmap({
    required MetricType selectedMetric,
    required ValueChanged<MetricType> onMetricChanged,
    Key? key,
    bool compact = true,
    Color? primaryColor,
    String? title,
  }) => MetricSelector(
    key: key,
    selectedMetric: selectedMetric,
    onMetricChanged: onMetricChanged,
    availableMetrics: MetricType.heatmapMetrics,
    compact: compact,
    primaryColor: primaryColor,
    title: title,
  );

  /// Factory constructor for trading context
  factory MetricSelector.trading({
    required MetricType selectedMetric,
    required ValueChanged<MetricType> onMetricChanged,
    Key? key,
    bool compact = true,
    Color? primaryColor,
    String? title,
  }) => MetricSelector(
    key: key,
    selectedMetric: selectedMetric,
    onMetricChanged: onMetricChanged,
    availableMetrics: MetricType.tradingMetrics,
    compact: compact,
    primaryColor: primaryColor,
    title: title,
  );

  /// Currently selected metric
  final MetricType selectedMetric;

  /// Callback when metric changes
  final ValueChanged<MetricType> onMetricChanged;

  /// Available metric options (defaults to portfolio metrics)
  final List<MetricType>? availableMetrics;

  /// Whether to show as compact chips instead of segmented control
  final bool compact;

  /// Primary color for the selector
  final Color? primaryColor;

  /// Whether to show icons alongside text
  final bool showIcons;

  /// Whether to use full display names instead of short names
  final bool useDisplayNames;

  /// Optional title for the selector
  final String? title;

  /// Whether to show as dropdown instead of chips/segments
  final bool asDropdown;

  @override
  Widget build(BuildContext context) {
    final metrics = availableMetrics ?? MetricType.portfolioMetrics;

    CommonLogger.debug(
      'MetricSelector: building with ${metrics.length} options, selected=${selectedMetric.shortName}',
      tag: 'Heatmap.Metric',
    );
    Widget selector;

    if (asDropdown) {
      selector = _buildDropdownSelector(context, metrics);
    } else if (compact) {
      selector = _buildCompactSelector(context, metrics);
    } else {
      selector = _buildSegmentedSelector(context, metrics);
    }

    if (title != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title!,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          selector,
        ],
      );
    }

    return selector;
  }

  Widget _buildSegmentedSelector(
    BuildContext context,
    List<MetricType> metrics,
  ) {
    final children = Map<MetricType, String>.fromEntries(
      metrics.map(
        (metric) => MapEntry(
          metric,
          useDisplayNames ? metric.displayName : metric.shortName,
        ),
      ),
    );

    return AppSegmentedControl<MetricType>(
      selectedValue: selectedMetric,
      children: children,
      onValueChanged: (metric) {
        CommonLogger.debug(
          'Metric changed: ${selectedMetric.shortName} → ${metric.shortName}',
          tag: 'Heatmap.Filter',
        );
        onMetricChanged(metric);
      },
      primaryColor: primaryColor,
    );
  }

  Widget _buildCompactSelector(
    BuildContext context,
    List<MetricType> metrics,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: metrics.map((metric) {
      final isSelected = metric == selectedMetric;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            CommonLogger.debug(
              'Metric changed: ${selectedMetric.shortName} → ${metric.shortName}',
              tag: 'Heatmap.Filter',
            );
            onMetricChanged(metric);
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 40,
            ), // Better touch target
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? (primaryColor ?? Theme.of(context).primaryColor)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? (primaryColor ?? Theme.of(context).primaryColor)
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: (primaryColor ?? Theme.of(context).primaryColor)
                            .withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcons) ...[
                  Icon(
                    metric.icon,
                    size: 16,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  useDisplayNames ? metric.displayName : metric.shortName,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );

  Widget _buildDropdownSelector(
    BuildContext context,
    List<MetricType> metrics,
  ) => DropdownButtonFormField<MetricType>(
    value: selectedMetric,
    decoration: InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      isDense: true,
    ),
    items: metrics
        .map(
          (metric) => DropdownMenuItem<MetricType>(
            value: metric,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcons) ...[
                  Icon(metric.icon, size: 16),
                  const SizedBox(width: 8),
                ],
                Text(
                  useDisplayNames ? metric.displayName : metric.shortName,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        )
        .toList(),
    onChanged: (metric) {
      if (metric != null) {
        CommonLogger.debug(
          'Metric changed: ${selectedMetric.shortName} → ${metric.shortName}',
          tag: 'Heatmap.Filter',
        );
        onMetricChanged(metric);
      }
    },
  );
}
