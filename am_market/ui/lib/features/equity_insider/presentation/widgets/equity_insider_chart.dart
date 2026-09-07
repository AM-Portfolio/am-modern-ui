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

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 310,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Price Performance & Chart',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: TimeFrameSelector(
                      selectedTimeFrame: _selectedTimeFrame,
                      primaryColor: ModuleColors.market,
                      availableTimeFrames: const [
                        TimeFrame.oneDay,
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
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: chartDataAsync.when(
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

                    return ComparisonChartView(
                      data: chartData,
                      config: MultiSeriesChartConfig(
                        timeFrameCode: tfCode,
                        embedMode: true,
                        height: 270, // Increased to fill 310 space correctly
                        showExpandButton: false,
                        initialShowAbsoluteValues: true,
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
                            onPressed: () => ref.refresh(equityStockChartDataProvider(query)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: context.borderColor),
                              foregroundColor: context.textPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            child: const Text('Retry', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
