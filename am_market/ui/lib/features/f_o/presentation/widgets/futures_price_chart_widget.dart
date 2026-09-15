import 'package:am_design_system/am_design_system.dart';
import 'package:am_design_system/shared/widgets/charts/candle_chart.dart';
import 'package:am_market_ui/core/styles/market_theme_extension.dart';
import 'package:am_market_ui/features/f_o/providers/fo_provider.dart';
import 'package:am_market_ui/features/f_o/providers/futures_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FuturesPriceChartWidget extends ConsumerStatefulWidget {
  const FuturesPriceChartWidget({super.key});

  @override
  ConsumerState<FuturesPriceChartWidget> createState() => _FuturesPriceChartWidgetState();
}

class _FuturesPriceChartWidgetState extends ConsumerState<FuturesPriceChartWidget> {
  TimeFrame _selectedTimeframe = TimeFrame.oneMonth;
  String _selectedChartType = 'Candle';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final marketTheme = context.marketTheme;
    final activeSymbol = ref.watch(foActiveSymbolProvider) ?? 'NIFTY';
    final selectedContract = ref.watch(selectedFutureContractProvider);
    final contracts = ref.watch(futuresContractsProvider).maybeWhen(data: (d) => d, orElse: () => <dynamic>[]);

    final firstContract = contracts.isNotEmpty && contracts.first is Map ? Map<String, dynamic>.from(contracts.first) : null;
    final activeContract = selectedContract ?? firstContract;
    final tradingSymbol = activeContract != null
        ? (activeContract['trading_symbol'] ?? activeContract['tradingSymbol'] ?? activeContract['name'] ?? '$activeSymbol FUT').toString()
        : '$activeSymbol FUT';

    final currentLtp = activeContract != null && activeContract['ltp'] is num
        ? (activeContract['ltp'] as num).toDouble()
        : 0.0;

    final candles = ref.watch(
      futuresHistoricalChartProvider(
        FuturesChartParams(
          symbol: tradingSymbol,
          timeFrame: _selectedTimeframe,
          currentLtp: currentLtp,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.5),
        border: Border.all(color: colors.border.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar: Title, Timeframes, Chart Type
          Row(
            children: [
              Text('Price Chart', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tradingSymbol,
                  style: TextStyle(color: colors.textSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Design System TimeFrame Selector
              TimeFrameSelector(
                selectedTimeFrame: _selectedTimeframe,
                availableTimeFrames: TimeFrame.tradingTimeFrames,
                compact: true,
                onTimeFrameChanged: (tf) => setState(() => _selectedTimeframe = tf),
              ),
              const SizedBox(width: 8),
              // Candle / Line Toggle Dropdown
              InkWell(
                onTap: () => setState(() {
                  _selectedChartType = _selectedChartType == 'Candle' ? 'Line' : 'Candle';
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border.all(color: colors.border),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedChartType == 'Candle' ? Icons.candlestick_chart_rounded : Icons.show_chart_rounded,
                        size: 14,
                        color: ModuleColors.market,
                      ),
                      const SizedBox(width: 4),
                      Text(_selectedChartType, style: TextStyle(color: colors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (candles.isEmpty)
            SizedBox(
              height: 270,
              child: Center(
                child: Text('No OHLC chart data available', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              ),
            )
          else
            Builder(
              builder: (context) {
                final latest = candles.last;
                final change = latest.close - candles.first.close;
                final pChange = candles.first.close > 0 ? (change / candles.first.close) * 100 : 0.0;
                final isPos = change >= 0;
                final deltaColor = isPos ? marketTheme.positive : marketTheme.negative;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // OHLC Readout Bar
                    Row(
                      children: [
                        _buildOhlcItem('O', latest.open.toStringAsFixed(2), colors),
                        _buildOhlcItem('H', latest.high.toStringAsFixed(2), colors),
                        _buildOhlcItem('L', latest.low.toStringAsFixed(2), colors),
                        _buildOhlcItem('C', latest.close.toStringAsFixed(2), colors),
                        const SizedBox(width: 8),
                        Text(
                          '${isPos ? '+' : ''}${change.toStringAsFixed(2)} (${isPos ? '+' : ''}${pChange.toStringAsFixed(2)}%)',
                          style: TextStyle(color: deltaColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Integrated Design System Chart View
                    SizedBox(
                      height: 220,
                      child: _selectedChartType == 'Candle'
                          ? CandleChartView(
                              key: ValueKey('candle_${_selectedTimeframe.code}_$tradingSymbol'),
                              candles: candles,
                              config: const CommonChartConfig(
                                showGrid: true,
                                showTitles: true,
                                showTooltips: true,
                              ),
                              upColor: marketTheme.positive,
                              downColor: marketTheme.negative,
                            )
                          : ChartFactory.line(
                              data: candles
                                  .map((c) => CommonChartDataPoint(
                                        x: c.x,
                                        y: c.close,
                                        xLabel: c.xLabel,
                                        yLabel: c.close.toStringAsFixed(2),
                                      ))
                                  .toList(),
                              config: const CommonChartConfig(
                                showGrid: true,
                                showTitles: true,
                                showTooltips: true,
                              ),
                              color: ModuleColors.market,
                              height: 220,
                            ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildOhlcItem(String label, String val, AppColorsTheme colors) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Row(
        children: [
          Text('$label ', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.bold, fontSize: 11)),
          Text(val, style: TextStyle(color: colors.textPrimary, fontSize: 11)),
        ],
      ),
    );
  }
}
