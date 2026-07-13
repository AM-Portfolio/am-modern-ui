import 'package:flutter/material.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:am_design_system/core/utils/common_logger.dart';


import 'package:am_common/am_common.dart';
import '../inputs/app_segmented_control.dart';

/// Get common time frames for portfolio analysis
const List<TimeFrame> portfolioTimeFrames = [
  TimeFrame.oneMonth,
  TimeFrame.threeMonths,
  TimeFrame.sixMonths,
  TimeFrame.oneYear,
  TimeFrame.ytd,
  TimeFrame.all,
];

/// Get common time frames for heatmap analysis
const List<TimeFrame> heatmapTimeFrames = [
  TimeFrame.oneDay,
  TimeFrame.oneWeek,
  TimeFrame.oneMonth,
  TimeFrame.threeMonths,
  TimeFrame.oneYear,
];

/// Get trading time frames (shorter periods)
const List<TimeFrame> tradingTimeFrames = [
  TimeFrame.oneDay,
  TimeFrame.oneWeek,
  TimeFrame.oneMonth,
  TimeFrame.threeMonths,
];

/// Get mobile-optimized time frames (limited selection)
const List<TimeFrame> mobileTimeFrames = [
  TimeFrame.oneDay,
  TimeFrame.oneWeek,
  TimeFrame.oneMonth,
  TimeFrame.threeMonths,
  TimeFrame.oneYear,
];

/// Get web-optimized time frames (full selection)
const List<TimeFrame> webTimeFrames = [
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

/// Get dashboard / app-wide time frames (alias of [TimeFrame.appTimeFrames]).
List<TimeFrame> get dashboardTimeFrames => TimeFrame.appTimeFrames;

/// Widget for selecting time frames with customizable options
class TimeFrameSelector extends StatefulWidget {
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
  State<TimeFrameSelector> createState() => _TimeFrameSelectorState();
}

class _TimeFrameSelectorState extends State<TimeFrameSelector> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected(animated: false);
    });
  }

  @override
  void didUpdateWidget(covariant TimeFrameSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTimeFrame != oldWidget.selectedTimeFrame) {
      _scrollToSelected(animated: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelected({required bool animated}) {
    if (!_scrollController.hasClients) return;

    final timeFrames = widget.availableTimeFrames ?? TimeFrame.portfolioTimeFrames;
    final index = timeFrames.indexOf(widget.selectedTimeFrame);
    if (index == -1) return;

    // Approximate width of compact timeframe items:
    // Minimum width is 40, plus 24 horizontal padding inside the container = ~40-42 width.
    // Plus 2px spacing on the right of each item = ~44.0.
    const double itemWidth = 44.0;
    const double viewportWidth = 132.0; // Fits exactly 3 items at a time

    final double targetOffset = (index * itemWidth) - (viewportWidth / 2) + (itemWidth / 2);
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double clampedOffset = targetOffset.clamp(0.0, maxScroll);

    if (animated) {
      _scrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      _scrollController.jumpTo(clampedOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFrames = widget.availableTimeFrames ?? TimeFrame.portfolioTimeFrames;

    CommonLogger.debug(
      'TimeFrameSelector: building with ${timeFrames.length} options, selected=${widget.selectedTimeFrame.code}',
      tag: 'Heatmap.TimeFrame',
    );

    // Create children map for the selector
    final children = Map<TimeFrame, String>.fromEntries(
      timeFrames.map(
        (timeFrame) => MapEntry(
          timeFrame,
          widget.showDisplayNames ? timeFrame.displayName : timeFrame.code,
        ),
      ),
    );

    Widget selector;

    if (widget.compact) {
      selector = _buildCompactSelector(context, timeFrames);
    } else {
      selector = AppSegmentedControl<TimeFrame>(
        selectedValue: widget.selectedTimeFrame,
        children: children,
        onValueChanged: (timeFrame) {
          CommonLogger.debug(
            'TimeFrame changed: ${widget.selectedTimeFrame.code} → ${timeFrame.code}',
            tag: 'Heatmap.Filter',
          );
          widget.onTimeFrameChanged(timeFrame);
        },
        primaryColor: widget.primaryColor,
      );
    }

    if (widget.title != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title!,
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
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = widget.primaryColor ?? AppColors.primary;
    final barBg = isDark
        ? Colors.white.withOpacity(0.06)
        : theme.colorScheme.surfaceContainerHighest;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.1)
        : theme.colorScheme.outline.withOpacity(0.2);
    final idleText = isDark
        ? Colors.white.withOpacity(0.65)
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: barBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: timeFrames.map((timeFrame) {
            final isSelected = timeFrame == widget.selectedTimeFrame;

            return Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    CommonLogger.debug(
                      'TimeFrame changed: ${widget.selectedTimeFrame.code} → ${timeFrame.code}',
                      tag: 'Heatmap.Filter',
                    );
                    widget.onTimeFrameChanged(timeFrame);
                  },
                  borderRadius: BorderRadius.circular(7),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    constraints: const BoxConstraints(minHeight: 32, minWidth: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        widget.showDisplayNames ? timeFrame.displayName : timeFrame.code,
                        style: TextStyle(
                          color: isSelected ? Colors.white : idleText,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
