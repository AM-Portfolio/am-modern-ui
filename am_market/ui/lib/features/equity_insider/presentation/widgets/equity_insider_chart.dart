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
        final isMobile = constraints.maxWidth < AmBreakpoints.mobile;
        final chartHeight = isMobile ? 210.0 : 260.0;
        final totalHeight = isMobile ? 280.0 : 330.0;
        final title = isMobile ? 'Price Performance' : 'Price Performance & Chart';

        return SizedBox(
          height: totalHeight,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
                  if (isMobile) ...[
                    const Spacer(),
                    SizedBox(
                      width: 72,
                      child: CustomDropdown<TimeFrame>(
                        value: timeFrames.contains(_selectedTimeFrame)
                            ? _selectedTimeFrame
                            : TimeFrame.oneYear,
                        height: 36,
                        isExpanded: true,
                        fontSize: 12,
                        iconSize: 16,
                        borderRadius: 10,
                        menuMaxHeight: 148,
                        primaryColor: ModuleColors.market,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
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
                    ),
                  ],
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
                        height: chartHeight,
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
                            onPressed: () =>
                                ref.refresh(equityStockChartDataProvider(query)),
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
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: TimeFrameSelector(
                      selectedTimeFrame: _selectedTimeFrame,
                      primaryColor: ModuleColors.market,
                      availableTimeFrames: timeFrames,
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
            ],
          ),
        );
      },
    );
  }
}
