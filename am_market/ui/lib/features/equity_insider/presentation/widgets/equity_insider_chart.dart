import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../../core/styles/market_theme_extension.dart';
import '../../providers/equity_insider_provider.dart';

/// Equity Insider Interactive Stock Price Chart.
///
/// Directly reuses [ComparisonChartView] and [MultiIndexChart] from [am_design_system]
/// to guarantee zero duplicate canvas/chart logic while inheriting rich interactive features:
/// - Pinch zoom and pan
/// - % Change vs Absolute Price (₹) toggle
/// - Series toggle (show/hide)
/// - Crosshair hover & tooltip scrubbing
/// - Full dynamic dark/light theme adherence
class EquityInsiderChart extends ConsumerStatefulWidget {
  final String symbol;

  const EquityInsiderChart({
    super.key,
    required this.symbol,
  });

  @override
  ConsumerState<EquityInsiderChart> createState() => _EquityInsiderChartState();
}

class _EquityInsiderChartState extends ConsumerState<EquityInsiderChart> {
  TimeFrame _selectedTimeFrame = TimeFrame.oneYear;
  bool _showAbsoluteValues = true;

  String _timeFrameToCode(TimeFrame tf) {
    switch (tf) {
      case TimeFrame.oneDay:
        return '1D';
      case TimeFrame.oneWeek:
        return '1W';
      case TimeFrame.oneMonth:
        return '1M';
      case TimeFrame.threeMonths:
        return '3M';
      case TimeFrame.sixMonths:
        return '6M';
      case TimeFrame.oneYear:
        return '1Y';
      case TimeFrame.threeYears:
        return '3Y';
      case TimeFrame.fiveYears:
        return '5Y';
      case TimeFrame.all:
        return 'ALL';
      default:
        return tf.code.toUpperCase();
    }
  }

  Widget _unitToggle() {
    return SizedBox(
      key: const Key('comparison-chart-unit-toggle'),
      width: kComparisonChartToolbarControlWidth,
      height: kComparisonChartHeaderRowHeight,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: (Theme.of(context).brightness == Brightness.dark)
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: _unitToggleSegment(
                label: '%',
                isSelected: !_showAbsoluteValues,
                onTap: () {
                  if (_showAbsoluteValues) {
                    setState(() => _showAbsoluteValues = false);
                  }
                },
              ),
            ),
            Expanded(
              child: _unitToggleSegment(
                label: '123',
                isSelected: _showAbsoluteValues,
                onTap: () {
                  if (!_showAbsoluteValues) {
                    setState(() => _showAbsoluteValues = true);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unitToggleSegment({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected
        ? ModuleColors.market
        : (Theme.of(context).brightness == Brightness.dark
            ? Colors.white70
            : Colors.black87);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? ModuleColors.market.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _timeFrameDropdown(List<TimeFrame> timeFrames) {
    return SizedBox(
      width: kComparisonChartToolbarControlWidth,
      child: CustomDropdown<TimeFrame>(
        value: timeFrames.contains(_selectedTimeFrame)
            ? _selectedTimeFrame
            : TimeFrame.oneYear,
        height: kComparisonChartHeaderRowHeight,
        isExpanded: true,
        fontSize: 12,
        iconSize: 16,
        borderRadius: 10,
        menuMaxHeight: 148,
        primaryColor: ModuleColors.market,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        items: timeFrames
            .map(
              (tf) => tf.toSimpleDropdownItem(
                text: tf.code,
                fontSize: 12,
              ),
            )
            .toList(),
        onChanged: (tf) {
          if (tf != null) {
            setState(() => _selectedTimeFrame = tf);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeExchange = ref.watch(selectedExchangeProvider);
    final tfCode = _timeFrameToCode(_selectedTimeFrame);
    final query = EquityChartQuery(symbol: widget.symbol, timeframe: tfCode, exchange: activeExchange);
    final chartDataAsync = ref.watch(equityStockChartDataProvider(query));

    const timeFrames = [
      TimeFrame.oneDay,
      TimeFrame.oneMonth,
      TimeFrame.sixMonths,
      TimeFrame.oneYear,
      TimeFrame.fiveYears,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.sizeOf(context).width < 800;
        final hasBoundedHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0;
        final totalHeight = hasBoundedHeight
            ? constraints.maxHeight
            : (isMobile ? 280.0 : 330.0);
        final chartHeight = (totalHeight - 44).clamp(160.0, 400.0);

        return SizedBox(
          height: totalHeight,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: kComparisonChartHeaderRowHeight,
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Performance Chart',
                              key: const Key('ei-chart-title'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: context.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: (activeExchange == 'BSE'
                                      ? context.colors.statusWarning
                                      : context.marketTheme.chartBlue)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              activeExchange,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: activeExchange == 'BSE'
                                    ? context.colors.statusWarning
                                    : context.marketTheme.chartBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _timeFrameDropdown(timeFrames),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, inner) {
                    if (inner.maxHeight < 120) {
                      return const SizedBox.shrink();
                    }
                    return chartDataAsync.when(
                      data: (chartData) {
                        if (chartData.series.isEmpty) {
                          return Center(
                            child: Text(
                              'No price data for ${widget.symbol} ($tfCode)',
                              style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          width: inner.maxWidth,
                          height: inner.maxHeight,
                          child: ComparisonChartView(
                            data: chartData,
                            config: MultiSeriesChartConfig(
                              timeFrameCode: tfCode,
                              embedMode: true,
                              height: hasBoundedHeight ? null : chartHeight,
                              showExpandButton: false,
                              showUnitToggle: false,
                              legendTrailing: _unitToggle(),
                              initialShowAbsoluteValues: _showAbsoluteValues,
                            ),
                          ),
                        );
                      },
                      loading: () => const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        ),
                      ),
                      error: (err, stack) => Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Failed to load chart: $err',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              OutlinedButton(
                                onPressed: () => ref.refresh(
                                  equityStockChartDataProvider(query),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: context.borderColor),
                                  foregroundColor: context.textPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                ),
                                child: const Text(
                                  'Retry',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
