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
  String _selectedTimeframe = '1M';
  String _selectedChartType = 'Candle';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final marketTheme = context.marketTheme;
    final activeSymbol = ref.watch(foActiveSymbolProvider) ?? 'TCS';
    final selectedContract = ref.watch(selectedFutureContractProvider);

    final tradingSymbol = selectedContract != null
        ? (selectedContract['trading_symbol'] ?? selectedContract['tradingSymbol'] ?? '$activeSymbol FUT 24 SEP 26').toString()
        : '$activeSymbol FUT 24 SEP 26';

    final timeframes = ['1D', '1W', '1M', '3M', '1Y'];
    final candles = _generateCandles(_selectedTimeframe);

    // Latest OHLC values
    final latest = candles.last;
    final change = latest.close - candles.first.close;
    final pChange = (change / candles.first.close) * 100;
    final isPos = change >= 0;
    final deltaColor = isPos ? marketTheme.positive : marketTheme.negative;

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
              Text(tradingSymbol, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
              const Spacer(),
              // Timeframe Chips
              Row(
                children: timeframes.map((tf) {
                  final isSel = _selectedTimeframe == tf;
                  return InkWell(
                    onTap: () => setState(() => _selectedTimeframe = tf),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: isSel ? ModuleColors.market : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tf,
                        style: TextStyle(
                          color: isSel ? Colors.black : colors.textSecondary,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 8),
              // Candle / Line Dropdown
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

          // Integrated Design System Candle Chart View
          SizedBox(
            height: 240,
            child: _selectedChartType == 'Candle'
                ? CandleChartView(
                    key: ValueKey('candle_$_selectedTimeframe'),
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
                    data: candles.map((c) => CommonChartDataPoint(
                      x: c.x,
                      y: c.close,
                      xLabel: c.xLabel,
                      yLabel: c.close.toStringAsFixed(2),
                    )).toList(),
                    config: const CommonChartConfig(
                      showGrid: true,
                      showTitles: true,
                      showTooltips: true,
                    ),
                    color: ModuleColors.market,
                    height: 240,
                  ),
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

  List<CommonCandlePoint> _generateCandles(String tf) {
    late final List<String> dates;
    late final List<List<double>> rawPoints;

    switch (tf) {
      case '1D':
        dates = ['09:15', '10:30', '11:45', '13:00', '14:15', '15:30'];
        rawPoints = [
          [2203.50, 2208.00, 2201.00, 2206.20],
          [2206.20, 2212.50, 2204.00, 2210.80],
          [2210.80, 2214.00, 2207.50, 2209.00],
          [2209.00, 2211.50, 2202.00, 2204.50],
          [2204.50, 2207.00, 2199.50, 2201.20],
          [2201.20, 2205.80, 2200.00, 2203.50],
        ];
        break;
      case '1W':
        dates = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
        rawPoints = [
          [2192.00, 2210.00, 2188.00, 2205.50],
          [2205.50, 2222.00, 2200.00, 2218.00],
          [2218.00, 2228.00, 2210.00, 2214.50],
          [2214.50, 2219.00, 2195.00, 2198.00],
          [2198.00, 2208.50, 2194.00, 2203.50],
        ];
        break;
      case '3M':
        dates = ['Jul W1', 'Jul W3', 'Aug W1', 'Aug W3', 'Sep W1', 'Sep W3'];
        rawPoints = [
          [2145.00, 2178.00, 2135.00, 2168.00],
          [2168.00, 2195.00, 2160.00, 2188.00],
          [2188.00, 2220.00, 2180.00, 2210.00],
          [2210.00, 2245.00, 2202.00, 2235.00],
          [2235.00, 2250.00, 2200.00, 2215.00],
          [2215.00, 2225.00, 2195.00, 2203.50],
        ];
        break;
      case '1Y':
        dates = ['Oct', 'Dec', 'Feb', 'Apr', 'Jun', 'Aug', 'Sep'];
        rawPoints = [
          [1980.00, 2040.00, 1965.00, 2025.00],
          [2025.00, 2110.00, 2015.00, 2095.00],
          [2095.00, 2150.00, 2075.00, 2135.00],
          [2135.00, 2190.00, 2120.00, 2175.00],
          [2175.00, 2240.00, 2160.00, 2220.00],
          [2220.00, 2280.00, 2210.00, 2250.00],
          [2250.00, 2260.00, 2190.00, 2203.50],
        ];
        break;
      case '1M':
      default:
        dates = ['1 Sep', '4 Sep', '8 Sep', '11 Sep', '15 Sep', '18 Sep', '22 Sep', '25 Sep', '26 Sep'];
        rawPoints = [
          [2195.00, 2212.00, 2185.00, 2208.00],
          [2208.00, 2218.00, 2198.00, 2205.00],
          [2205.00, 2230.00, 2200.00, 2225.00],
          [2225.00, 2242.00, 2220.00, 2235.00],
          [2235.00, 2238.00, 2202.00, 2215.00],
          [2215.00, 2218.00, 2188.00, 2196.00],
          [2196.00, 2222.00, 2190.00, 2212.00],
          [2212.00, 2228.00, 2208.00, 2218.00],
          [2218.00, 2224.00, 2200.00, 2203.50],
        ];
        break;
    }

    return List.generate(dates.length, (i) {
      final p = rawPoints[i];
      return CommonCandlePoint(
        x: i.toDouble(),
        open: p[0],
        high: p[1],
        low: p[2],
        close: p[3],
        xLabel: dates[i],
      );
    });
  }
}
