import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:am_design_system/core/theme/app_colors.dart';
import 'package:am_design_system/core/theme/app_typography.dart';
import 'package:am_design_system/core/config/design_system_provider.dart';
import 'chart_types.dart';



/// Factory widget for creating standardized charts
class ChartFactory extends StatelessWidget {
  final ChartType type;
  final List<CommonChartDataPoint> data;
  final CommonChartConfig config;
  final Color? primaryColor;
  final double height;

  const ChartFactory({
    required this.type,
    required this.data,
    super.key,
    this.config = const CommonChartConfig(),
    this.primaryColor,
    this.height = 300,
  });

  /// Factory constructor for Line Chart
  factory ChartFactory.line({
    required List<CommonChartDataPoint> data,
    CommonChartConfig config = const CommonChartConfig(),
    Color? color,
    double height = 300,
  }) {
    return ChartFactory(
      type: ChartType.line,
      data: data,
      config: config,
      primaryColor: color,
      height: height,
    );
  }

  /// Factory constructor for Bar Chart
  factory ChartFactory.bar({
    required List<CommonChartDataPoint> data,
    CommonChartConfig config = const CommonChartConfig(),
    Color? color,
    double height = 300,
  }) {
    return ChartFactory(
      type: ChartType.bar,
      data: data,
      config: config,
      primaryColor: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: _buildChart(context),
    );
  }

  Widget _buildChart(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: AppTypography.getTextTheme(
            isDark: Theme.of(context).brightness == Brightness.dark
          ).bodyMedium,
        ),
      );
    }

    switch (type) {
      case ChartType.line:
      case ChartType.area:
        return _buildLineChart(context);
      case ChartType.bar:
        return _buildBarChart(context);
      case ChartType.pie:
      case ChartType.donut:
        return _buildPieChart(context);
      case ChartType.table:
        return _buildTableChart(context);
    }
  }

  Widget _buildTableChart(BuildContext context) {
    return SingleChildScrollView(
      child: Table(
        border: TableBorder.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        children: [
          TableRow(
             decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest),
             children: const [
               Padding(padding: EdgeInsets.all(8.0), child: Text('Label', style: TextStyle(fontWeight: FontWeight.bold))),
               Padding(padding: EdgeInsets.all(8.0), child: Text('Value', style: TextStyle(fontWeight: FontWeight.bold))),
             ]
          ),
          ...data.map((point) => TableRow(
            children: [
              Padding(padding: const EdgeInsets.all(8.0), child: Text(point.xLabel ?? '')),
              Padding(padding: const EdgeInsets.all(8.0), child: Text(point.yLabel ?? point.y.toStringAsFixed(2))),
            ]
          )),
        ],
      ),
    );
  }

  Widget _buildLineChart(BuildContext context) {
    final theme = Theme.of(context);
    final designConfig = DesignSystemProvider.of(context);
    final color = primaryColor ?? designConfig.primaryColor;
    final gridColor = config.gridColor ?? theme.dividerColor.withOpacity(0.1);
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: config.showGrid,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: gridColor,
            strokeWidth: 1,
            dashArray: [5, 5],
          ),
        ),
        titlesData: FlTitlesData(
          show: config.showTitles,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                // Simple index-based label retrieval
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      data[index].xLabel ?? '',
                      style: TextStyle(fontSize: 10, color: theme.hintColor),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 10, color: theme.hintColor),
              ),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: data.map((d) => FlSpot(d.x, d.y)).toList(),
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: type == ChartType.area,
              color: color.withOpacity(0.15),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: config.showTooltips,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.darkBackground.withOpacity(0.9),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final point = data[spot.spotIndex];
                return LineTooltipItem(
                  '${point.yLabel ?? point.y.toString()}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: point.xLabel ?? '',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
      duration: config.animate ? config.animationDuration : Duration.zero,
    );
  }

  Widget _buildBarChart(BuildContext context) {
    final theme = Theme.of(context);
    final designConfig = DesignSystemProvider.of(context);
    final color = primaryColor ?? designConfig.primaryColor;

    // Convert MainAxisAlignment to BarChartAlignment
    BarChartAlignment alignment = BarChartAlignment.spaceAround;
    if (config.barAlignment != null) {
      switch (config.barAlignment!) {
        case MainAxisAlignment.start:
          alignment = BarChartAlignment.start;
          break;
        case MainAxisAlignment.end:
          alignment = BarChartAlignment.end;
          break;
        case MainAxisAlignment.center:
          alignment = BarChartAlignment.center;
          break;
        case MainAxisAlignment.spaceBetween:
          alignment = BarChartAlignment.spaceBetween;
          break;
        case MainAxisAlignment.spaceAround:
          alignment = BarChartAlignment.spaceAround;
          break;
        case MainAxisAlignment.spaceEvenly:
          alignment = BarChartAlignment.spaceEvenly;
          break;
      }
    }

    return BarChart(
      BarChartData(
        alignment: alignment,
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          show: config.showTitles,
          bottomTitles: AxisTitles(
             sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                     padding: const EdgeInsets.only(top: 8),
                     child: Text(data[index].xLabel ?? '', style: TextStyle(fontSize: 10, color: theme.hintColor))
                  );
                }
                return const SizedBox();
              },
             )
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          final index = entry.key;
          final point = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: point.y,
                color: point.color ?? color,
                width: 16,
                borderRadius: BorderRadius.circular(designConfig.defaultRadius / 2),
              ),
            ],
          );
        }).toList(),
      ),
      duration: config.animate ? config.animationDuration : Duration.zero,
    );
  }

  Widget _buildPieChart(BuildContext context) {
    final sections = data.asMap().entries.map((entry) {
      final index = entry.key;
      final point = entry.value;
      final isTouched = false; // TODO: Implement touch if needed
      final radius = isTouched ? 60.0 : 50.0;
      
      // Default colors if not provided
      final defaultColors = [
        Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal
      ];
      final color = point.color ?? defaultColors[index % defaultColors.length];

      return PieChartSectionData(
        color: color,
        value: point.y,
        title: point.xLabel ?? '',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: type == ChartType.donut ? (config.pieCenterRadius > 0 ? config.pieCenterRadius : 40) : 0,
        sectionsSpace: 2,
      ),
      swapAnimationDuration: config.animate ? config.animationDuration : Duration.zero,
    );
  }
}
