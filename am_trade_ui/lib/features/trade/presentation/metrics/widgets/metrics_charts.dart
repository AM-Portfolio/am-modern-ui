import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class TradesByDayBarChart extends StatelessWidget {
  final Map<String, int> tradesByDay;

  const TradesByDayBarChart({super.key, required this.tradesByDay});

  @override
  Widget build(BuildContext context) {
    if (tradesByDay.isEmpty) {
      return const Center(child: Text("No Data"));
    }

    // Sort days chronologically if needed, or just map them
    // Assuming keys are like MONDAY, TUESDAY, etc.
    final days = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
    
    final data = days.mapIndexed((index, day) {
      final count = tradesByDay[day] ?? 0;
      return CommonChartDataPoint(
        x: index.toDouble(),
        y: count.toDouble(),
        xLabel: day.substring(0, 1),
        yLabel: count.toString(),
      );
    }).toList();

    return ChartFactory.bar(
      data: data,
      config: const CommonChartConfig(
        barAlignment: MainAxisAlignment.spaceBetween,
        showTitles: true,
        showGrid: true,
        animate: true,
      ),
      height: 200,
    );
  }
}

// Helper to get index with map
extension IterableExtension<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E e) f) sync* {
    var index = 0;
    for (final element in this) {
      yield f(index, element);
      index++;
    }
  }
}

class DistributionPieChart extends StatelessWidget {
  final Map<String, int> data;
  final bool animate;

  const DistributionPieChart({super.key, required this.data, this.animate = true});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text("No Data"));
    }

    final List<Color> colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.teal,
      Colors.pink,
    ];

    int colorIndex = 0;
    final chartData = data.entries.map((e) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      
      return CommonChartDataPoint(
        x: 0, // Not used for pie
        y: e.value.toDouble(),
        xLabel: '${e.key}\n${e.value}', // Used as title
        color: color,
      );
    }).toList();

    return ChartFactory(
      type: ChartType.pie,
      data: chartData,
      config: CommonChartConfig(
        animate: animate,
        showTitles: true,
      ),
      height: 200,
    );
  }
}

class ConsistencyGauge extends StatelessWidget {
  final double score; // 0 to 100

  const ConsistencyGauge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PieChart(
          PieChartData(
            startDegreeOffset: 180,
            sectionsSpace: 0,
            centerSpaceRadius: 60,
            sections: [
              PieChartSectionData(
                color: _getColorForScore(context, score),
                value: score,
                title: '',
                radius: 15,
              ),
              PieChartSectionData(
                color: Colors.grey.withOpacity(0.2),
                value: 100 - score,
                title: '',
                radius: 15,
              ),
              PieChartSectionData(
                color: Colors.transparent,
                value: 100, // Bottom half hidden
                title: '',
                radius: 15,
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${score.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getColorForScore(context, score),
                ),
              ),
              Text(
                'Score',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10), // Adjust for the gauge being top-half
            ],
          ),
        ),
      ],
    );
  }

  Color _getColorForScore(BuildContext context, double score) {
    final config = DesignSystemProvider.of(context);
    if (score >= 80) return config.successColor;
    if (score >= 50) return config.warningColor;
    return config.errorColor;
  }
}
