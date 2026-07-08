import 'package:am_dashboard_ui/domain/models/performance_response.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'glass_card.dart';

/// Performance chart — timeframe is controlled globally via [dashboardTimeFrameProvider].
class DashboardChartWidget extends StatefulWidget {
  final PerformanceResponse performance;

  const DashboardChartWidget({
    super.key,
    required this.performance,
  });

  @override
  State<DashboardChartWidget> createState() => _DashboardChartWidgetState();
}

class _DashboardChartWidgetState extends State<DashboardChartWidget> {
  bool _showGraph = true;

  List<DataPoint> get _chartData => widget.performance.chartData;

  bool get _hasPlottableData {
    if (_chartData.length < 2) return false;
    final values = _chartData.map((e) => e.value).toList();
    final minVal = values.reduce((a, b) => a < b ? a : b);
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    return maxVal > minVal || maxVal != 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final onSurface = isDark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final toggleBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F6F8);
    final emptyStateBg =
        isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFFAFAFA);

    final currencyFormat = NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);
    final returnPct = widget.performance.totalReturnPercentage;
    final returnVal = widget.performance.totalReturnValue;
    final isPositive = returnPct >= 0;
    final lastValue = _chartData.isNotEmpty ? _chartData.last.value : 0.0;

    return AmGlassCard(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasBoundedHeight =
              constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
          final chartArea = _showGraph
              ? (_hasPlottableData
                  ? _buildGraphView(isDark)
                  : _buildEmptyState(
                      emptyStateBg,
                      onSurfaceVariant,
                      isDark,
                    ))
              : (_chartData.isNotEmpty
                  ? _buildTableView(onSurface, onSurfaceVariant, isDark)
                  : _buildEmptyState(
                      emptyStateBg,
                      onSurfaceVariant,
                      isDark,
                    ));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Performance',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: onSurfaceVariant,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                currencyFormat.format(lastValue),
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: onSurface,
                                  fontFamily: 'Inter',
                                  letterSpacing: -0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                '${isPositive ? '+' : ''}${currencyFormat.format(returnVal)} (${returnPct.toStringAsFixed(2)}%)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isPositive
                                      ? const Color(0xFF00C853)
                                      : const Color(0xFFEF4444),
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: toggleBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildViewToggle('Graph', true, isDark),
                        _buildViewToggle('Table', false, isDark),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (hasBoundedHeight)
                Expanded(child: chartArea)
              else
                SizedBox(height: 280, child: chartArea),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    Color emptyStateBg,
    Color onSurfaceVariant,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: emptyStateBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Center(
        child: Text(
          'No performance data for ${widget.performance.timeFrame}',
          style: TextStyle(
            color: onSurfaceVariant,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildViewToggle(String label, bool isGraph, bool isDark) {
    final isSelected = _showGraph == isGraph;
    return GestureDetector(
      onTap: () => setState(() => _showGraph = isGraph),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? Colors.white : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? (isDark ? Colors.black : const Color(0xFF111827))
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)),
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildGraphView(bool isDark) {
    final values = _chartData.map((e) => e.value).toList();
    final rawMin = values.reduce((a, b) => a < b ? a : b);
    final rawMax = values.reduce((a, b) => a > b ? a : b);
    final span = (rawMax - rawMin).abs();
    final padding = span > 0 ? span * 0.1 : (rawMax.abs() * 0.1).clamp(1.0, double.infinity);
    final minY = rawMin - padding;
    final maxY = rawMax + padding;
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE2E8F0);

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: _chartData.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.value);
            }).toList(),
            isCurved: true,
            color: const Color(0xFF0062FF),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF0062FF).withValues(alpha: 0.1),
            ),
          ),
        ],
        titlesData: const FlTitlesData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: gridColor,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: true),
      ),
    );
  }

  Widget _buildTableView(Color onSurface, Color onSurfaceVariant, bool isDark) {
    final currencyFormat = NumberFormat.currency(symbol: '₹ ', decimalDigits: 2);
    final reversedData = List<DataPoint>.from(_chartData.reversed);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ListView.separated(
          itemCount: reversedData.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
          ),
          itemBuilder: (context, index) {
            final dp = reversedData[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dp.date,
                    style: TextStyle(
                      color: onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    currencyFormat.format(dp.value),
                    style: TextStyle(
                      color: onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
