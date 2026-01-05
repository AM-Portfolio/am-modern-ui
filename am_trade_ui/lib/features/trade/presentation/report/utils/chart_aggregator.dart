import 'package:intl/intl.dart';
import '../models/chart_config.dart';
import '../../../internal/domain/entities/report/daily_performance.dart';

class ChartAggregator {
  static List<ChartDataPoint> accumulateDaily(List<DailyPerformance> dailyData, ChartMetric metric) {
    // Sort by date just in case
    final sortedData = List.of(dailyData)..sort((a, b) => a.date.compareTo(b.date));
    
    return List.generate(sortedData.length, (index) {
       final item = sortedData[index];
       final val = metric.getValue(item.metrics, tradeCount: item.tradeCount);
       return ChartDataPoint(
         xLabel: DateFormat('MMM d').format(item.date),
         yValue: val,
         xIndex: index,
       );
    });
  }

  static List<ChartDataPoint> accumulateWeekly(List<DailyPerformance> dailyData, ChartMetric metric) {
    if (dailyData.isEmpty) return [];
    
    // key: Year-Week, value: List<DailyPerformance>
    final Map<String, List<DailyPerformance>> grouped = {};
    
    for (var item in dailyData) {
      // Simple way to get week number: use ISO week date or just divide day / 7 approximations.
      // Better: DateFormat('y-w')
      // Note: 'w' is week of year.
      final key = DateFormat('yyyy-ww').format(item.date);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    
    final sortedKeys = grouped.keys.toList()..sort();
    
    return List.generate(sortedKeys.length, (index) {
      final key = sortedKeys[index];
      final items = grouped[key]!;
      // Aggregate metric for the group
      final aggValue = _aggregateMetric(items, metric);
      
      // Label: "Wk 12\n'23"
      final labelDate = items.first.date;
      final label = 'W${DateFormat('w').format(labelDate)}\n${DateFormat('yy').format(labelDate)}';
      
      return ChartDataPoint(
        xLabel: label,
        yValue: aggValue,
        xIndex: index
      );
    });
  }

  static List<ChartDataPoint> accumulateMonthly(List<DailyPerformance> dailyData, ChartMetric metric) {
      if (dailyData.isEmpty) return [];

      // 1. Group existing data
      final Map<String, List<DailyPerformance>> grouped = {};
      for (var item in dailyData) {
        final key = DateFormat('yyyy-MM').format(item.date);
        grouped.putIfAbsent(key, () => []).add(item);
      }

      // 2. Determine Range
      // We rely on the fact that dailyData is sparse. We need min and max.
      DateTime minDate = dailyData.first.date;
      DateTime maxDate = dailyData.first.date;
      for (var item in dailyData) {
          if (item.date.isBefore(minDate)) minDate = item.date;
          if (item.date.isAfter(maxDate)) maxDate = item.date;
      }
      
      // Normalize to start/end of month
      minDate = DateTime(minDate.year, minDate.month, 1);
      maxDate = DateTime(maxDate.year, maxDate.month + 1, 0); // End of that month

      // 3. Generate steps
      List<ChartDataPoint> result = [];
      DateTime current = minDate;
      int index = 0;
      
      while (current.isBefore(maxDate) || current.isAtSameMomentAs(maxDate) || (current.year == maxDate.year && current.month == maxDate.month)) {
           final key = DateFormat('yyyy-MM').format(current);
           final items = grouped[key] ?? [];
           
           final aggValue = _aggregateMetric(items, metric);
           final label = DateFormat("MMM ''yy").format(current);
           
           result.add(ChartDataPoint(
               xLabel: label,
               yValue: aggValue,
               xIndex: index++
           ));
           
           // Next month
           // Safely increment month
           current = DateTime(current.year, current.month + 1, 1);
      }
      
      return result;
  }

  static double _aggregateMetric(List<DailyPerformance> items, ChartMetric metric) {
      if (items.isEmpty) return 0.0;
      
      double totalPnL = 0;
      int totalTrades = 0;
      int totalWins = 0;
      double totalHoldTime = 0; // assuming pre-summable or we avg it?
      
      // Pre-calc totals
      for(var i in items) {
          totalPnL += i.totalProfitLoss;
          totalTrades += i.tradeCount;
          totalWins += i.winCount;
          // For averages like 'Avg Hold Time', we technically need weighted avg
          // but metrics.avgHoldTime is per trade? 
          // Simple avg of averages is wrong. We need (avgHold * count).
          
          final hold = i.metrics.avgHoldTime ?? 0;
          totalHoldTime += (hold * i.tradeCount);
      }
      
      switch(metric) {
          case ChartMetric.grossPnL:
              return totalPnL; // SUM
          case ChartMetric.tradeCount:
              return totalTrades.toDouble(); // SUM
          case ChartMetric.winRate:
              if(totalTrades == 0) return 0;
              return (totalWins / totalTrades) * 100; // Recalculate %
          case ChartMetric.avgWin:
              // Helper needed, or simplify: Average of 'avgWin' is rough.
              // To do strictly right we need total win amount / win count.
              // We don't strictly have total win amount column in DailyPerformance directly exposed clean 
              // except derived from winRate/PnL potentially?
              // Let's use simple average of the daily values for now as an approximation or sum if it makes sense.
              // Actually average win amount * win count = total win $.
              // but we don't have 'average win amount' easily in `metrics` (it's in DailyPerformance top level actually? No, it's inside `metrics`).
              // Let's try to do weighted avg.
              
              double weightedTotal = 0;
              int counts = 0;
               for(var i in items) {
                   // avgWin * winCount
                   // We don't have winCount easily in metrics? 
                   // DailyPerformance has winCount.
                   final val = i.metrics.avgWin ?? 0;
                   weightedTotal += (val * i.winCount);
                   counts += i.winCount;
               }
               if(counts == 0) return 0;
              return weightedTotal / counts;

          case ChartMetric.avgLoss:
              double weightedTotal = 0;
              int counts = 0;
               for(var i in items) {
                   final val = i.metrics.avgLoss ?? 0;
                   weightedTotal += (val * i.lossCount);
                   counts += i.lossCount;
               }
               if(counts == 0) return 0;
              return weightedTotal / counts;
              
          case ChartMetric.holdTime:
              if (totalTrades == 0) return 0;
              return totalHoldTime / totalTrades;
              
          case ChartMetric.profitFactor:
               // Gross Profit / Gross Loss
               // We need Gross Profit and Gross Loss sums.
               // Approx: Average of profit factors is bad math.
               // Let's fallback to simple average for now to avoid complexity of reconstruction.
               double sum = 0;
               for(var i in items) sum += (i.metrics.profitFactor ?? 0);
               return sum / items.length;
      }
  }
}
