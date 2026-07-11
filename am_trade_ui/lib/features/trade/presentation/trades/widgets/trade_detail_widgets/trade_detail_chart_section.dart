import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/trade_holding_view_model.dart';

class TradeDetailChartSection extends StatefulWidget {
  final TradeHoldingViewModel trade;

  const TradeDetailChartSection({
    required this.trade,
    super.key,
  });

  @override
  State<TradeDetailChartSection> createState() => _TradeDetailChartSectionState();
}

class _TradeDetailChartSectionState extends State<TradeDetailChartSection> {
  String _selectedRange = '1D';
  final List<String> _ranges = ['1D', '1W', '1M', '1Y', 'ALL'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProfit = widget.trade.isProfit;
    
    // Fallback to a nice blue if it's not strictly profit/loss driven, 
    // but the mockup uses a beautiful primary color curve.
    final chartColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      height: 380,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Header with filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                // Ranges
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: _ranges.map((range) {
                      final isSelected = _selectedRange == range;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedRange = range),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            range,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected 
                                  ? theme.colorScheme.onPrimaryContainer 
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Spacer(),
                // Tools
                IconButton(
                  icon: const Icon(Icons.candlestick_chart, size: 18),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  tooltip: 'Candlesticks',
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen, size: 18),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  tooltip: 'Fullscreen',
                  onPressed: () {},
                ),
              ],
            ),
          ),
          
          // Chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 0, left: 0, top: 24, bottom: 0),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(
                    show: false, // Clean look like the mockup
                  ),
                  titlesData: const FlTitlesData(
                    show: false, // Clean look like the mockup
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateDummyData(),
                      isCurved: true,
                      color: chartColor, 
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            chartColor.withValues(alpha: 0.3),
                            chartColor.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateDummyData() {
    // Generate a nice looking spline curve data that matches the vibe of the mockup
    return const [
      FlSpot(0, 3.5),
      FlSpot(1, 3.2),
      FlSpot(2, 2.5),
      FlSpot(3, 2.8),
      FlSpot(4, 5.0),
      FlSpot(5, 7.5),
      FlSpot(6, 6.0),
      FlSpot(7, 4.0),
      FlSpot(8, 4.5),
      FlSpot(9, 6.0),
      FlSpot(10, 6.8),
    ];
  }
}
