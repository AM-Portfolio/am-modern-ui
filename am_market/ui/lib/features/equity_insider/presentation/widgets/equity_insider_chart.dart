import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_design_system/am_design_system.dart';
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

  @override
  Widget build(BuildContext context) {
    final tfCode = _timeFrameToCode(_selectedTimeFrame);
    final query = EquityChartQuery(symbol: widget.symbol, timeframe: tfCode);
    final chartDataAsync = ref.watch(equityStockChartDataProvider(query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Price performance & chart'),
        const SizedBox(height: 8),
        // Timeframe selector bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: TimeFrameSelector(
                  selectedTimeFrame: _selectedTimeFrame,
                  availableTimeFrames: const [
                    TimeFrame.oneDay,
                    TimeFrame.oneWeek,
                    TimeFrame.oneMonth,
                    TimeFrame.sixMonths,
                    TimeFrame.oneYear,
                    TimeFrame.fiveYears,
                  ],
                  onTimeFrameChanged: (newTf) {
                    setState(() {
                      _selectedTimeFrame = newTf;
                    });
                  },
                  compact: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Chart View Container
        Container(
          height: 380,
          width: double.infinity,
          decoration: BoxDecoration(
            color: context.cardColor,
            border: Border.all(color: context.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: chartDataAsync.when(
            data: (chartData) {
              if (chartData.series.isEmpty) {
                return Center(
                  child: Text(
                    'No price chart data available for ${widget.symbol} ($tfCode)',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                );
              }

              return ComparisonChartView(
                data: chartData,
                config: MultiSeriesChartConfig(
                  timeFrameCode: tfCode,
                  embedMode: true,
                  height: 360,
                  showExpandButton: false,
                  initialShowAbsoluteValues: true,
                ),
              );
            },
            loading: () => const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
            error: (err, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Failed to load chart: $err',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => ref.refresh(equityStockChartDataProvider(query)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.borderColor),
                      foregroundColor: context.textPrimary,
                    ),
                    child: const Text('Retry', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
              color: context.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: context.borderColor,
            ),
          ),
        ],
      ),
    );
  }
}
