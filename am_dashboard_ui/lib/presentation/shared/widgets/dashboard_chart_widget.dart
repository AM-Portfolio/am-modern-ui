import 'package:am_dashboard_ui/domain/models/performance_response.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:am_library/am_library.dart';
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
  bool _emittedEmpty = false;

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
    final isDark = context.isDark;
    final onSurface = context.textPrimary;
    final onSurfaceVariant = context.textSecondary;
    final toggleBgColor =
        isDark ? AppColors.darkCardLight : AppColors.lightBackground;
    final emptyStateBg = isDark
        ? AppColors.darkCardLight.withValues(alpha: 0.5)
        : AppColors.lightSurface;

    final currencyFormat = NumberFormat.currency(symbol: '₹ ', decimalDigits: 0);
    final returnPct = widget.performance.totalReturnPercentage;
    final returnVal = widget.performance.totalReturnValue;
    final lastValue = _chartData.isNotEmpty ? _chartData.last.value : 0.0;

    return AmGlassCard(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final hasBoundedHeight =
              constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
          final chartArea = _showGraph
              ? (_hasPlottableData
                  ? _buildGraphView(context)
                  : _buildEmptyState(
                      emptyStateBg,
                      onSurfaceVariant,
                    ))
              : (_chartData.isNotEmpty
                  ? _buildTableView(context, onSurface, onSurfaceVariant)
                  : _buildEmptyState(
                      emptyStateBg,
                      onSurfaceVariant,
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
                                '${returnPct >= 0 ? '+' : ''}${currencyFormat.format(returnVal)} (${returnPct.toStringAsFixed(2)}%)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.profitLossColor(returnPct),
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
                        _buildViewToggle('Graph', true),
                        _buildViewToggle('Table', false),
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
  ) {
    if (!_emittedEmpty) {
      _emittedEmpty = true;
      ProductTelemetry.instance.emptyState('dashboard_chart_empty');
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: emptyStateBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.borderColor),
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

  Widget _buildViewToggle(String label, bool isGraph) {
    final isSelected = _showGraph == isGraph;
    return GestureDetector(
      onTap: () => setState(() => _showGraph = isGraph),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.lightCard : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.shadow(0.05),
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
                ? AppColors.textPrimaryLight
                : context.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildGraphView(BuildContext context) {
    final values = _chartData.map((e) => e.value).toList();
    final rawMin = values.reduce((a, b) => a < b ? a : b);
    final rawMax = values.reduce((a, b) => a > b ? a : b);
    final span = (rawMax - rawMin).abs();
    final padding =
        span > 0 ? span * 0.1 : (rawMax.abs() * 0.1).clamp(1.0, double.infinity);
    final minY = rawMin - padding;
    final maxY = rawMax + padding;
    final gridColor = context.dividerColor;
    final lineColor = AppColors.info;

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
            color: lineColor,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: lineColor.withValues(alpha: 0.1),
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

  Widget _buildTableView(
    BuildContext context,
    Color onSurface,
    Color onSurfaceVariant,
  ) {
    final currencyFormat = NumberFormat.currency(symbol: '₹ ', decimalDigits: 2);
    final reversedData = List<DataPoint>.from(_chartData.reversed);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ListView.separated(
          itemCount: reversedData.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            color: context.dividerColor,
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
