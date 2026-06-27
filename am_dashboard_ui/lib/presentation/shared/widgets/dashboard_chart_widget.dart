import 'package:am_dashboard_ui/domain/models/performance_response.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'glass_card.dart';

/// Pixel-perfect Lumina performance chart widget.
/// Matches the image with custom timeframe picker at the top.
class DashboardChartWidget extends StatefulWidget {
  final PerformanceResponse performance;
  final ValueChanged<String>? onTimeFrameChanged;

  const DashboardChartWidget({
    super.key,
    required this.performance,
    this.onTimeFrameChanged,
  });

  @override
  State<DashboardChartWidget> createState() => _DashboardChartWidgetState();
}

class _DashboardChartWidgetState extends State<DashboardChartWidget> {
  late String _selectedTimeFrame;
  bool _showGraph = true;
  List<DataPoint> _mockDataPoints = [];

  @override
  void initState() {
    super.initState();
    _selectedTimeFrame = widget.performance.timeFrame.isNotEmpty 
        ? widget.performance.timeFrame 
        : '1M';
    _mockDataPoints = _generateMockData(_selectedTimeFrame);
  }

  void _onTimeFrameSelected(String tf) {
    setState(() {
      _selectedTimeFrame = tf;
      _mockDataPoints = _generateMockData(tf);
    });
    if (widget.onTimeFrameChanged != null) {
      widget.onTimeFrameChanged!(tf);
    }
  }

  List<DataPoint> _generateMockData(String timeFrame) {
    int points = 0;
    switch(timeFrame) {
      case '1D': points = 24; break;
      case '1W': points = 7; break;
      case '1M': points = 30; break;
      case '3M': points = 90; break;
      case '1Y': points = 12; break;
      case 'YTD': points = DateTime.now().month; break;
      default: points = 30;
    }

    final data = <DataPoint>[];
    final random = Random(42); // deterministic seed for aesthetic
    double value = 2500000.0; 
    final now = DateTime.now();

    for (int i = points; i >= 0; i--) {
      // Fluctuate randomly between -1% and +1.2%
      final changePercent = (random.nextDouble() * 2.2) - 1.0;
      value = value + (value * (changePercent / 100));
      
      String dateStr = '';
      if (timeFrame == '1D') {
        final time = now.subtract(Duration(hours: i));
        dateStr = '${time.hour}:00';
      } else if (timeFrame == '1W' || timeFrame == '1M' || timeFrame == '3M') {
        final time = now.subtract(Duration(days: i));
        dateStr = '${time.month}/${time.day}';
      } else {
        final time = DateTime(now.year, now.month - i, 1);
        dateStr = '${time.month}/${time.year}';
      }

      data.add(DataPoint(date: dateStr, value: value));
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Dynamic Colors based on theme
    final onSurface = isDark ? Colors.white : const Color(0xFF111827);
    final onSurfaceVariant = isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280);
    final toggleBgColor = isDark ? const Color(0xFF1E293B) : const Color(0xFFF4F6F8);
    final emptyStateBg = isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFFAFAFA);

    return AmGlassCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 580;

              final infoColumn = Column(
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
                      Text(
                        '₹2,745,538',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: onSurface,
                          fontFamily: 'Inter',
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          '+₹12,450 (0.45%)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF00C853),
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );

              final controlsRow = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Graph vs Table Toggle
                  Container(
                    decoration: BoxDecoration(
                      color: toggleBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        _buildViewToggle('Graph', true, isDark),
                        _buildViewToggle('Table', false, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Timeframe Picker
                  Container(
                    decoration: BoxDecoration(
                      color: toggleBgColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: ['1D', '1W', '1M', '3M', '1Y', 'YTD'].map((tf) {
                        final isSelected = tf == _selectedTimeFrame;
                        return GestureDetector(
                          onTap: () => _onTimeFrameSelected(tf),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              tf,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: isSelected 
                                    ? (isDark ? Colors.black : const Color(0xFF111827)) 
                                    : onSurfaceVariant,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    infoColumn,
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: controlsRow,
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  infoColumn,
                  controlsRow,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          
          if (_mockDataPoints.isEmpty)
            Expanded(
              child: Container(
                width: double.infinity, // Explicit bounds to prevent render box error
                decoration: BoxDecoration(
                  color: emptyStateBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart, color: onSurfaceVariant.withValues(alpha: 0.5), size: 32),
                      const SizedBox(height: 16),
                      Text(
                        'Real-time charting active',
                        style: TextStyle(
                          color: onSurfaceVariant,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AGGREGATING GLOBAL FEEDS',
                        style: TextStyle(
                          color: onSurfaceVariant.withValues(alpha: 0.7),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: SizedBox(
                width: double.infinity, // Explicit width for fl_chart to avoid crash
                child: _showGraph 
                    ? _buildGraphView() 
                    : _buildTableView(onSurface, onSurfaceVariant, isDark),
              ),
            ),
        ],
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

  Widget _buildGraphView() {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: _mockDataPoints.asMap().entries.map((e) {
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
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildTableView(Color onSurface, Color onSurfaceVariant, bool isDark) {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final reversedData = List<DataPoint>.from(_mockDataPoints.reversed);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ListView.separated(
          itemCount: reversedData.length,
          separatorBuilder: (context, index) => Divider(
            height: 1, 
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)
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
