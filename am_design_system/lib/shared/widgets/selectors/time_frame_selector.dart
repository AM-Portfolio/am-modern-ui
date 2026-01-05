import 'package:flutter/material.dart';
import 'package:am_design_system/core/utils/common_logger.dart';


import '../inputs/app_segmented_control.dart';

/// Enum for time frame options
enum TimeFrame {
  oneDay('1D', '1 Day'),
  oneWeek('1W', '1 Week'),
  oneMonth('1M', '1 Month'),
  threeMonths('3M', '3 Months'),
  sixMonths('6M', '6 Months'),
  oneYear('1Y', '1 Year'),
  ytd('YTD', 'Year to Date'),
  threeYears('3Y', '3 Years'),
  fiveYears('5Y', '5 Years'),
  all('ALL', 'All Time');

  const TimeFrame(this.code, this.displayName);

  /// Short code for the time frame
  final String code;

  /// Display name for the time frame
  final String displayName;

  /// Get time frame from code
  static TimeFrame? fromCode(String code) {
    for (final timeFrame in TimeFrame.values) {
      if (timeFrame.code == code) {
        return timeFrame;
      }
    }
    return null;
  }

  /// Get common time frames for portfolio analysis
  static List<TimeFrame> get portfolioTimeFrames => [
    TimeFrame.oneMonth,
    TimeFrame.threeMonths,
    TimeFrame.sixMonths,
    TimeFrame.oneYear,
    TimeFrame.ytd,
    TimeFrame.all,
  ];

  /// Get common time frames for heatmap analysis
  static List<TimeFrame> get heatmapTimeFrames => [
    TimeFrame.oneDay,
    TimeFrame.oneWeek,
    TimeFrame.oneMonth,
    TimeFrame.threeMonths,
    TimeFrame.oneYear,
  ];

  /// Get trading time frames (shorter periods)
  static List<TimeFrame> get tradingTimeFrames => [
    TimeFrame.oneDay,
    TimeFrame.oneWeek,
    TimeFrame.oneMonth,
    TimeFrame.threeMonths,
  ];

  /// Get mobile-optimized time frames (limited selection)
  static List<TimeFrame> get mobileTimeFrames => [
    TimeFrame.oneDay,
    TimeFrame.oneWeek,
    TimeFrame.oneMonth,
    TimeFrame.threeMonths,
    TimeFrame.oneYear,
  ];

  /// Get web-optimized time frames (full selection)
  static List<TimeFrame> get webTimeFrames => [
    TimeFrame.oneDay,
    TimeFrame.oneWeek,
    TimeFrame.oneMonth,
    TimeFrame.threeMonths,
    TimeFrame.sixMonths,
    TimeFrame.oneYear,
    TimeFrame.ytd,
    TimeFrame.threeYears,
    TimeFrame.fiveYears,
    TimeFrame.all,
  ];

  /// Get dashboard time frames (quick selection)
  static List<TimeFrame> get dashboardTimeFrames => [
    TimeFrame.oneDay,
    TimeFrame.oneWeek,
    TimeFrame.oneMonth,
    TimeFrame.oneYear,
  ];
}

/// Widget for selecting time frames with customizable options
class TimeFrameSelector extends StatelessWidget {
  /// Constructor
  const TimeFrameSelector({
    required this.selectedTimeFrame,
    required this.onTimeFrameChanged,
    super.key,
    this.availableTimeFrames,
    this.compact = false,
    this.primaryColor,
    this.showDisplayNames = false,
    this.title,
  });

  /// Factory constructor for portfolio context
  factory TimeFrameSelector.portfolio({
    required TimeFrame selectedTimeFrame,
    required ValueChanged<TimeFrame> onTimeFrameChanged,
    Key? key,
    bool compact = false,
    Color? primaryColor,
    String? title,
  }) => TimeFrameSelector(
    key: key,
    selectedTimeFrame: selectedTimeFrame,
    onTimeFrameChanged: onTimeFrameChanged,
    availableTimeFrames: TimeFrame.portfolioTimeFrames,
    compact: compact,
    primaryColor: primaryColor,
    title: title,
  );

  /// Factory constructor for heatmap context
  factory TimeFrameSelector.heatmap({
    required TimeFrame selectedTimeFrame,
    required ValueChanged<TimeFrame> onTimeFrameChanged,
    Key? key,
    bool compact = true,
    Color? primaryColor,
    String? title,
  }) => TimeFrameSelector(
    key: key,
    selectedTimeFrame: selectedTimeFrame,
    onTimeFrameChanged: onTimeFrameChanged,
    availableTimeFrames: TimeFrame.heatmapTimeFrames,
    compact: compact,
    primaryColor: primaryColor,
    title: title,
  );

  /// Factory constructor for trading context
  factory TimeFrameSelector.trading({
    required TimeFrame selectedTimeFrame,
    required ValueChanged<TimeFrame> onTimeFrameChanged,
    Key? key,
    bool compact = true,
    Color? primaryColor,
    String? title,
  }) => TimeFrameSelector(
    key: key,
    selectedTimeFrame: selectedTimeFrame,
    onTimeFrameChanged: onTimeFrameChanged,
    availableTimeFrames: TimeFrame.tradingTimeFrames,
    compact: compact,
    primaryColor: primaryColor,
    title: title,
  );

  /// Currently selected time frame
  final TimeFrame selectedTimeFrame;

  /// Callback when time frame changes
  final ValueChanged<TimeFrame> onTimeFrameChanged;

  /// Available time frame options (defaults to portfolio time frames)
  final List<TimeFrame>? availableTimeFrames;

  /// Whether to show as compact pills instead of segmented control
  final bool compact;

  /// Primary color for the selector
  final Color? primaryColor;

  /// Whether to show display names instead of codes
  final bool showDisplayNames;

  /// Optional title for the selector
  final String? title;

  @override
  Widget build(BuildContext context) {
    final timeFrames = availableTimeFrames ?? TimeFrame.portfolioTimeFrames;

    CommonLogger.debug(
      'TimeFrameSelector: building with ${timeFrames.length} options, selected=${selectedTimeFrame.code}',
      tag: 'Heatmap.TimeFrame',
    );

    // Create children map for the selector
    final children = Map<TimeFrame, String>.fromEntries(
      timeFrames.map(
        (timeFrame) => MapEntry(
          timeFrame,
          showDisplayNames ? timeFrame.displayName : timeFrame.code,
        ),
      ),
    );

    Widget selector;

    if (compact) {
      selector = _buildCompactSelector(context, timeFrames);
    } else {
      selector = AppSegmentedControl<TimeFrame>(
        selectedValue: selectedTimeFrame,
        children: children,
        onValueChanged: (timeFrame) {
          CommonLogger.debug(
            'TimeFrame changed: ${selectedTimeFrame.code} → ${timeFrame.code}',
            tag: 'Heatmap.Filter',
          );
          onTimeFrameChanged(timeFrame);
        },
        primaryColor: primaryColor,
      );
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

  Widget _buildCompactSelector(
    BuildContext context,
    List<TimeFrame> timeFrames,
  ) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: timeFrames.map((timeFrame) {
      final isSelected = timeFrame == selectedTimeFrame;

      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            CommonLogger.debug(
              'TimeFrame changed: ${selectedTimeFrame.code} → ${timeFrame.code}',
              tag: 'Heatmap.Filter',
            );
            onTimeFrameChanged(timeFrame);
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
            child: Center(
              child: Text(
                showDisplayNames ? timeFrame.displayName : timeFrame.code,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );
}
