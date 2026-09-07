import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:am_design_system/am_design_system.dart';

class FinancialChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const FinancialChartCard({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: context.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class FinancialBarChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> dataList;
  final String label1Key;
  final String? label1Fallback;
  final String label2Key;
  final String? label2Fallback;
  final Color color1;
  final Color color2;
  final String name1;
  final String name2;
  final bool isQuarterly;

  const FinancialBarChartWidget({
    super.key,
    required this.dataList,
    required this.label1Key,
    this.label1Fallback,
    required this.label2Key,
    this.label2Fallback,
    required this.color1,
    required this.color2,
    required this.name1,
    required this.name2,
    this.isQuarterly = false,
  });

  double _val(Map<String, dynamic> row, String key, [String? fallback]) {
    final v = row[key] ?? (fallback != null ? row[fallback] : null);
    if (v is num) return v.toDouble();
    if (v is String) {
      final clean = v.replaceAll(RegExp(r'[^\d.-]'), '');
      return double.tryParse(clean) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final barGroups = <BarChartGroupData>[];
    double maxY = 0;

    for (int i = 0; i < dataList.length; i++) {
      final row = dataList[i];
      final val1 = _val(row, label1Key, label1Fallback);
      final val2 = _val(row, label2Key, label2Fallback);

      if (val1 > maxY) maxY = val1;
      if (val2 > maxY) maxY = val2;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val1,
              color: color1.withValues(alpha: 0.9),
              width: 7,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
              ),
            ),
            BarChartRodData(
              toY: val2,
              color: color2.withValues(alpha: 0.9),
              width: 7,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(2),
              ),
            ),
          ],
        ),
      );
    }

    maxY = maxY * 1.15;
    if (maxY == 0) maxY = 100;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        barGroups: barGroups,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => context.cardColor,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final row = dataList[group.x];
              final period = (row['period'] ?? '').toString();
              final val = rod.toY.toInt();
              final String seriesName = rodIndex == 0 ? name1 : name2;
              return BarTooltipItem(
                '$period\n$seriesName: ₹$val Cr',
                TextStyle(
                  color: context.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= dataList.length) return const SizedBox();
                final String period =
                    (dataList[value.toInt()]['period'] ?? '').toString();
                final parts = period.split(' ');
                String shortPeriod = period;
                if (!isQuarterly && parts.length == 2 && parts[1].length == 4) {
                  shortPeriod = 'FY${parts[1].substring(2)}';
                } else if (parts.length == 2 && parts[1].length == 4) {
                  shortPeriod = '${parts[0]} ${parts[1].substring(2)}';
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    shortPeriod,
                    style: TextStyle(color: context.textSecondary, fontSize: 9),
                  ),
                );
              },
              reservedSize: 22,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == maxY) return const SizedBox();
                String text = value.toInt().toString();
                if (value >= 1000) {
                  text = '${(value / 1000).round()}K';
                }
                return Text(
                  text,
                  style: TextStyle(color: context.textTertiary, fontSize: 9),
                  textAlign: TextAlign.right,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: context.borderColor.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class FinancialChartLegend extends StatelessWidget {
  final List<FinancialLegendItem> items;

  const FinancialChartLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.map((e) {
        return Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: e.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                e.label,
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class FinancialLegendItem {
  final Color color;
  final String label;
  const FinancialLegendItem({required this.color, required this.label});
}
