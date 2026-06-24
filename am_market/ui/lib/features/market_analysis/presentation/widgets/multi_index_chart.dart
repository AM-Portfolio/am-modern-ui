import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// Multi-index chart widget that displays up to 3 indices on a single chart
class MultiIndexChart extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> historicalData;
  final List<String> selectedIndices;
  final bool isLoading;
  final String? error;
  final bool isBarChart;

  const MultiIndexChart({
    super.key,
    required this.historicalData,
    required this.selectedIndices,
    this.isLoading = false,
    this.error,
    this.isBarChart = false,
  });

  // Color palette for different indices
  static const List<Color> indexColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFFEF4444), // Red
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Violet
  ];

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(color: Color(0xFF00D1FF)),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red, fontSize: 14),
          ),
        ),
      );
    }

    if (selectedIndices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Select up to 3 indices to compare',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Prepare chart data
    final chartData = _prepareChartData();
    if (chartData.isEmpty) {
      return Center(
        child: Text(
          'No historical data available',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      );
    }

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegend(context),
          const SizedBox(height: 24),
          Expanded(
            child: isBarChart
                ? _buildBarChart(context, chartData)
                : _buildChart(context, chartData),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: selectedIndices.asMap().entries.map((entry) {
        final index = entry.key;
        final symbol = entry.value;
        final color = indexColors[index % indexColors.length];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              symbol,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildBarChart(
      BuildContext context, List<Map<String, dynamic>> chartData) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure enough width for bars
        final minWidth =
            chartData.length * (selectedIndices.length * 10.0 + 20.0);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: minWidth > constraints.maxWidth
                ? minWidth
                : constraints.maxWidth,
            height: constraints.maxHeight,
            child: BarChart(
              // Fixes horizontal stretching measurement glitches by forcing a fresh layout on load
              key: ValueKey('${selectedIndices.join('-')}_bar_${chartData.length}'),
              BarChartData(
                // Dynamic dashed horizontal gridlines that adjust perfectly with Y-axis percentages
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.dividerColor.withOpacity(0.15),
                      strokeWidth: 1,
                      dashArray: [4, 4], // Clean dashes instead of solid lines
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < chartData.length) {
                          // Show fewer labels if too many
                          if (chartData.length > 20 &&
                              index % (chartData.length ~/ 10) != 0) {
                            return const SizedBox.shrink();
                          }

                          final dateStr = chartData[index]['time'] as String;
                          try {
                            final date = DateTime.parse(dateStr);
                            final fmt = _getDateFormat(chartData);

                            // If the previous tick formats to the same string, skip it to prevent duplicates
                            final interval = (chartData.length > 20)
                                ? (chartData.length ~/ 10)
                                : 1;
                            final prevIndex =
                                ((index - 1) ~/ interval) * interval;
                            if (prevIndex >= 0) {
                              try {
                                final prevDate = DateTime.parse(
                                    chartData[prevIndex]['time'] as String);
                                if (fmt.format(prevDate) == fmt.format(date)) {
                                  return const SizedBox.shrink();
                                }
                              } catch (_) {}
                            }

                            return SideTitleWidget(
                              meta: meta,
                              space: 8.0,
                              child: Text(
                                fmt.format(date),
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.6),
                                  fontSize: 10,
                                ),
                              ),
                            );
                          } catch (e) {
                            return const SizedBox.shrink();
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      // Symmetrical 5-tick grid calculation: Divides the total vertical range into 4 equal blocks,
                      // mathematically guaranteeing exactly 5 symmetrical ticks across the Y-axis.
                      interval: (() {
                        final min = _getMinPrice(chartData);
                        final max = _getMaxPrice(chartData);
                        final range = max - min;
                        return range > 0 ? range / 4 : 1.0;
                      })(),
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          space: 8.0,
                          child: Text(
                            '${value.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.6),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                        color: theme.dividerColor.withOpacity(0.5), width: 1),
                    left: BorderSide(
                        color: theme.dividerColor.withOpacity(0.5), width: 1),
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                minY: _getMinPrice(chartData),
                maxY: _getMaxPrice(chartData),
                barGroups: chartData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final point = entry.value;

                  return BarChartGroupData(
                    x: index,
                    barsSpace: 4,
                    barRods: selectedIndices.asMap().entries.map((idxEntry) {
                      final idx = idxEntry.key;
                      final symbol = idxEntry.value;
                      final val = (point[symbol] as num?)?.toDouble() ?? 0.0;
                      // Logic: If value < 0, use RED, else use Index Color
                      final isNegative = val < 0;
                      final color = isNegative
                          ? const Color(0xFFEF4444)
                          : indexColors[idx % indexColors.length];

                      return BarChartRodData(
                        toY: val,
                        color: color,
                        width: 14, // Fixed width
                        borderRadius: val > 0
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(2),
                                topRight: Radius.circular(2))
                            : const BorderRadius.only(
                                bottomLeft: Radius.circular(2),
                                bottomRight: Radius.circular(2)),
                        backDrawRodData: BackgroundBarChartRodData(
                            show: true, toY: 0, color: Colors.transparent),
                      );
                    }).toList(),
                  );
                }).toList(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final dateStr = chartData[group.x]['time'] as String;
                      final date = DateTime.parse(dateStr);
                      final symbol = selectedIndices[rodIndex];
                      return BarTooltipItem(
                        '${_getTooltipDateFormat(chartData).format(date)}\n$symbol\n${rod.toY.toStringAsFixed(2)}%',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChart(
      BuildContext context, List<Map<String, dynamic>> chartData) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: chartData.length * 30.0 > constraints.maxWidth
                ? chartData.length * 30.0
                : constraints.maxWidth,
            height: constraints.maxHeight,
            child: LineChart(
              // Fixes horizontal stretching measurement glitches by forcing a fresh layout on load
              key: ValueKey('${selectedIndices.join('-')}_line_${chartData.length}'),
              LineChartData(
                // Dynamic dashed horizontal gridlines that adjust perfectly with Y-axis percentages
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.dividerColor.withOpacity(0.15),
                      strokeWidth: 1,
                      dashArray: [4, 4], // Clean dashes instead of solid lines
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: (chartData.length / 8).ceilToDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < chartData.length) {
                          final interval = (chartData.length / 8).ceil();
                          // Skip the final boundary tick if it's too close to the last regular interval tick
                          // to prevent duplicate/crowded labels at the end.
                          if (index == chartData.length - 1 && interval > 1) {
                            final lastIntervalTick =
                                ((chartData.length - 1) ~/ interval) * interval;
                            if (chartData.length - 1 != lastIntervalTick &&
                                chartData.length - 1 - lastIntervalTick <
                                    interval / 2) {
                              return const SizedBox.shrink();
                            }
                          }

                          final dateStr = chartData[index]['time'] as String;
                          try {
                            final date = DateTime.parse(dateStr);
                            final fmt = _getDateFormat(chartData);

                            // DEDUPLICATION LOGIC:
                            // Stock charts can have multiple data points on the same day (e.g. market open and close).
                            // When formatting with 'dd MMM' or 'E', they resolve to identical day strings (e.g., 'Mon' or '15 Jun').
                            // We determine the index of the previously printed interval step:
                            // - For standard intervals, this is the previous step (e.g. index 18 for step 21).
                            // - For forced edge ticks (e.g. index 19), this finds the last printed multiple (index 18).
                            final prevIndex =
                                ((index - 1) ~/ interval) * interval;
                            if (prevIndex >= 0) {
                              try {
                                final prevDate = DateTime.parse(
                                    chartData[prevIndex]['time'] as String);
                                // If the current label matches the previous label, skip rendering it
                                if (fmt.format(prevDate) == fmt.format(date)) {
                                  return const SizedBox.shrink();
                                }
                              } catch (_) {}
                            }

                            return SideTitleWidget(
                              meta: meta,
                              space: 8.0,
                              child: Text(
                                fmt.format(date),
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.6),
                                  fontSize: 10,
                                ),
                              ),
                            );
                          } catch (e) {
                            return const SizedBox.shrink();
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      // Symmetrical 5-tick grid calculation: Divides the total vertical range into 4 equal blocks,
                      // mathematically guaranteeing exactly 5 symmetrical ticks across the Y-axis.
                      interval: (() {
                        final min = _getMinPrice(chartData);
                        final max = _getMaxPrice(chartData);
                        final range = max - min;
                        return range > 0 ? range / 4 : 1.0;
                      })(),
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          meta: meta,
                          space: 8.0,
                          child: Text(
                            '${value.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.6),
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                        color: theme.dividerColor.withOpacity(0.5), width: 1),
                    left: BorderSide(
                        color: theme.dividerColor.withOpacity(0.5), width: 1),
                    top: BorderSide.none,
                    right: BorderSide.none,
                  ),
                ),
                minX: 0,
                maxX: chartData.length.toDouble() - 1,
                minY: _getMinPrice(chartData),
                maxY: _getMaxPrice(chartData),
                // Highlighted horizontal baseline drawn at exactly 0.0% to instantly separate profits/losses
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 0.0,
                      color: theme.colorScheme.primary.withOpacity(0.35),
                      strokeWidth: 1.5,
                      dashArray: [4, 4], // Highlighted dashed baseline
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        style: TextStyle(
                          color: theme.colorScheme.primary.withOpacity(0.8),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                lineBarsData: _buildLineBars(chartData),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final index = spot.x.toInt();
                        if (index >= 0 && index < chartData.length) {
                          final dateStr = chartData[index]['time'] as String;
                          final date = DateTime.parse(dateStr);
                          final symbol = selectedIndices[spot.barIndex];
                          final percentChange = spot.y;

                          return LineTooltipItem(
                            '${_getTooltipDateFormat(chartData).format(date)}\n$symbol: ${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(2)}%',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _prepareChartData() {
    if (selectedIndices.isEmpty) return [];

    // Helper to normalize timestamps (strip fractional seconds/millis)
    String normalizeTime(String timeStr) {
      try {
        final dt = DateTime.parse(timeStr);
        return '${dt.year.toString().padLeft(4, '0')}-'
            '${dt.month.toString().padLeft(2, '0')}-'
            '${dt.day.toString().padLeft(2, '0')}T'
            '${dt.hour.toString().padLeft(2, '0')}:'
            '${dt.minute.toString().padLeft(2, '0')}:'
            '${dt.second.toString().padLeft(2, '0')}';
      } catch (_) {
        return timeStr;
      }
    }

    // Get all unique timestamps across selected indices
    final Set<String> allTimestamps = {};
    for (final symbol in selectedIndices) {
      final data = historicalData[symbol];
      if (data != null) {
        for (final point in data) {
          final time = point['time'] as String;
          allTimestamps.add(normalizeTime(time));
        }
      }
    }

    // Sort timestamps
    final sortedTimestamps = allTimestamps.toList()..sort();

    // Get baseline (first) prices for each index
    final Map<String, double> baselinePrices = {};
    for (final symbol in selectedIndices) {
      final data = historicalData[symbol];
      if (data != null && data.isNotEmpty) {
        // Find the first price for this symbol
        for (final timestamp in sortedTimestamps) {
          final matchingPoint = data.firstWhere(
            (p) {
              final pTime = p['time'] as String?;
              return pTime != null && normalizeTime(pTime) == timestamp;
            },
            orElse: () => {},
          );
          if (matchingPoint.isNotEmpty) {
            baselinePrices[symbol] = (matchingPoint['close'] as num).toDouble();
            break;
          }
        }
      }
    }

    // Build combined data points with percentage change
    final List<Map<String, dynamic>> combined = [];
    for (final timestamp in sortedTimestamps) {
      final Map<String, dynamic> point = {'time': timestamp};

      for (final symbol in selectedIndices) {
        final data = historicalData[symbol];
        if (data != null && baselinePrices.containsKey(symbol)) {
          final matchingPoint = data.firstWhere(
            (p) {
              final pTime = p['time'] as String?;
              return pTime != null && normalizeTime(pTime) == timestamp;
            },
            orElse: () => {},
          );
          if (matchingPoint.isNotEmpty) {
            final price = (matchingPoint['close'] as num).toDouble();
            final baseline = baselinePrices[symbol]!;
            // Calculate percentage change from baseline
            final percentChange = ((price - baseline) / baseline) * 100;
            point[symbol] = percentChange;
          }
        }
      }

      // LINE ALIGNMENT FILTER (Option 1 - Intersection):
      // Only add this date point to the chart if ALL selected indices have valid price data.
      // This crops the chart timeline to matching days, ensuring both lines start and end at the exact same pixel.
      if (point.length == selectedIndices.length + 1) {
        combined.add(point);
      }
    }

    return combined;
  }

  List<LineChartBarData> _buildLineBars(List<Map<String, dynamic>> chartData) {
    return selectedIndices.asMap().entries.map((entry) {
      final index = entry.key;
      final symbol = entry.value;
      final color = indexColors[index % indexColors.length];

      final spots = <FlSpot>[];
      for (int i = 0; i < chartData.length; i++) {
        final value = chartData[i][symbol];
        if (value != null) {
          spots.add(FlSpot(i.toDouble(), value as double));
        }
      }

      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 2.5,
        isStrokeCapRound: true,
        dotData: FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0.0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      );
    }).toList();
  }

  /// Helper method to dynamically determine date formatting on the X-axis
  /// based on the date range span of the available chart data.
  DateFormat _getDateFormat(List<Map<String, dynamic>> chartData) {
    if (chartData.isEmpty) return DateFormat('MMM yy');
    try {
      final firstDate = DateTime.parse(chartData.first['time'] as String);
      final lastDate = DateTime.parse(chartData.last['time'] as String);
      final difference = lastDate.difference(firstDate);

      if (difference.inDays <= 1) {
        return DateFormat('HH:mm');
      } else if (difference.inDays <= 7) {
        return DateFormat(
            'E'); // Just show day of the week (e.g. Tue, Wed) for clean view
      } else if (difference.inDays <= 120) {
        return DateFormat('dd MMM');
      } else {
        return DateFormat('MMM yy');
      }
    } catch (_) {
      return DateFormat('MMM yy');
    }
  }

  /// Helper method to dynamically determine date formatting for tooltips
  /// based on the date range span of the available chart data.
  DateFormat _getTooltipDateFormat(List<Map<String, dynamic>> chartData) {
    if (chartData.isEmpty) return DateFormat('dd MMM yy');
    try {
      final firstDate = DateTime.parse(chartData.first['time'] as String);
      final lastDate = DateTime.parse(chartData.last['time'] as String);
      final difference = lastDate.difference(firstDate);

      // Include hour:minute time precision in tooltip if the span is a week or less
      if (difference.inDays <= 7) {
        return DateFormat('dd MMM yy HH:mm');
      }
      return DateFormat('dd MMM yy');
    } catch (_) {
      return DateFormat('dd MMM yy');
    }
  }

  double _calculateInterval(List<Map<String, dynamic>> chartData) {
    if (chartData.isEmpty) return 1.0;
    final min = _getMinPrice(chartData);
    final max = _getMaxPrice(chartData);
    final range = max - min;
    if (range <= 0) return 1.0;

    // Suggest a clean, rounded interval based on the range size
    final rawInterval = range / 5;
    if (rawInterval < 0.25) return 0.25;
    if (rawInterval < 0.5) return 0.5;
    if (rawInterval < 1.0) return 1.0;
    if (rawInterval < 2.0) return 2.0;
    if (rawInterval < 5.0) return 5.0;
    return (rawInterval / 5).ceil() * 5.0;
  }

  double _getMinPrice(List<Map<String, dynamic>> chartData) {
    double min = double.infinity;
    for (final point in chartData) {
      for (final symbol in selectedIndices) {
        final value = point[symbol];
        if (value != null && value < min) {
          min = value as double;
        }
      }
    }
    return min == double.infinity ? -5 : min - 1; // Add padding
  }

  double _getMaxPrice(List<Map<String, dynamic>> chartData) {
    double max = double.negativeInfinity;
    for (final point in chartData) {
      for (final symbol in selectedIndices) {
        final value = point[symbol];
        if (value != null && value > max) {
          max = value as double;
        }
      }
    }
    return max == double.negativeInfinity ? 5 : max + 1; // Add padding
  }
}
