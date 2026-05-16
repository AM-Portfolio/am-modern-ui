import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart' as ds;
import '../services/real_analysis_service.dart';
import 'package:am_analysis_core/am_analysis_core.dart';

import 'package:intl/intl.dart';

/// Responsive performance chart widget with time frame and chart type selectors
class AnalysisPerformanceWidget extends StatefulWidget {
  const AnalysisPerformanceWidget({
    required this.portfolioId,
    this.initialTimeFrame = ds.TimeFrame.oneMonth,
    this.height,
    this.showTimeFrameSelector = true,
    this.authToken,
    super.key,
  });

  final String portfolioId;
  final ds.TimeFrame initialTimeFrame;
  final double? height;
  final bool showTimeFrameSelector;
  final String? authToken;

  @override
  State<AnalysisPerformanceWidget> createState() => _AnalysisPerformanceWidgetState();
}

enum ChartType { line, area, bar }

class _AnalysisPerformanceWidgetState extends State<AnalysisPerformanceWidget> {
  late final RealAnalysisService _service;
  late ds.TimeFrame _selectedTimeFrame;
  ChartType _chartType = ChartType.area;
  bool _isLoading = true;
  String? _error;
  List<PerformanceDataPoint> _dataPoints = [];

  @override
  void initState() {
    super.initState();
    _selectedTimeFrame = widget.initialTimeFrame;
    _initService();
  }

  Future<void> _initService() async {
    if (widget.authToken != null) {
      _service = RealAnalysisService(authToken: widget.authToken);
    } else {
      final storage = SecureStorageService();
      final token = await storage.getAccessToken();
      _service = RealAnalysisService(authToken: token != null ? 'Bearer $token' : null);
    }
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('[Performance] Loading data for portfolio=${widget.portfolioId}, timeFrame=${_selectedTimeFrame.code}');
      final points = await _service.getPerformance(
        widget.portfolioId,
        AnalysisEntityType.PORTFOLIO,
        _selectedTimeFrame.code,
      );
      if (mounted) {
        setState(() {
          _dataPoints = points;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('[Performance] Error loading data: $e');
      print('[Performance] Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _error = 'Failed to load performance: ${e.toString().replaceAll('Exception:', '').trim()}';
          _isLoading = false;
        });
      }
    }
  }

  void _onTimeFrameChanged(ds.TimeFrame timeFrame) {
    setState(() {
      _selectedTimeFrame = timeFrame;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;
        final height = widget.height ?? (isMobile ? 320 : isTablet ? 300 : 280);
        final padding = isMobile ? 16.0 : 20.0;

        return SizedBox(
          height: height,
          child: ds.AppCard(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.all(padding),
            borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Performance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 15 : 16,
                      ),
                    ),
                    if (widget.showTimeFrameSelector)
                      ds.TimeFrameSelector.portfolio(
                        selectedTimeFrame: _selectedTimeFrame,
                        onTimeFrameChanged: _onTimeFrameChanged,
                        compact: true,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(child: _buildContent(isMobile, isTablet)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(bool isMobile, bool isTablet) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_dataPoints.isEmpty) {
      return Center(
        child: Text(
          'No performance data available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }

    // Check if all data points are zero
    final allZero = _dataPoints.every((p) => p.value == 0);
    if (allZero) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.query_stats, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Text(
              'Performance data pending calculation',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    return _buildChart();
  }

  Widget _buildChart() {
    final spots = _dataPoints.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    final minY = _dataPoints.map((p) => p.value).reduce((a, b) => a < b ? a : b);
    final maxY = _dataPoints.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final isPositive = _dataPoints.last.value >= _dataPoints.first.value;
    
    final gainColor = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF00B894) : const Color(0xFF009975);
    final lossColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFF7675) : const Color(0xFFE85656);
    final chartColor = isPositive ? gainColor : lossColor;
    
    // Interval calculation for X axis
    final xInterval = (_dataPoints.length / 5).ceil().toDouble();

    if (_chartType == ChartType.bar) {
      return BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY).abs() < 0.001 ? 1.0 : (maxY - minY).abs() / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: minY - ((maxY - minY).abs() * 0.1).clamp(0.1, 1000000),
          maxY: maxY + ((maxY - minY).abs() * 0.1).clamp(0.1, 1000000),
          barGroups: spots.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value.y,
                  color: chartColor,
                  width: 4,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              ],
            );
          }).toList(),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY).abs() < 0.001 ? 1.0 : (maxY - minY).abs() / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: xInterval > 0 ? xInterval : 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= _dataPoints.length) {
                  return const SizedBox.shrink();
                }
                
                final date = _dataPoints[index].date;
                String text;
                
                if (_selectedTimeFrame == ds.TimeFrame.oneDay) {
                  text = DateFormat('HH:mm').format(date);
                } else if (_selectedTimeFrame == ds.TimeFrame.oneMonth) {
                  text = DateFormat('MMM d').format(date);
                } else if (_selectedTimeFrame == ds.TimeFrame.sixMonths || 
                           _selectedTimeFrame == ds.TimeFrame.oneYear ||
                           _selectedTimeFrame == ds.TimeFrame.ytd) {
                  text = DateFormat('MMM').format(date);
                } else {
                  text = DateFormat('MMM yy').format(date);
                }
                
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    text,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: minY - ((maxY - minY).abs() * 0.1).clamp(0.1, 1000000),
        maxY: maxY + ((maxY - minY).abs() * 0.1).clamp(0.1, 1000000),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: _chartType == ChartType.area || _chartType == ChartType.line,
            color: chartColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: _chartType == ChartType.area
                ? BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        chartColor.withValues(alpha: 0.3),
                        chartColor.withValues(alpha: 0.0),
                      ],
                    ),
                  )
                : BarAreaData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => Theme.of(context).cardColor.withValues(alpha: 0.9),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = _dataPoints[spot.x.toInt()].date;
                final formattedDate = DateFormat('MMM d, yyyy').format(date);
                
                return LineTooltipItem(
                  '${_formatCurrency(spot.y)}\n$formattedDate',
                  TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 10000000) {
      return '₹${(value / 10000000).toStringAsFixed(2)} Cr';
    } else if (value >= 100000) {
      return '₹${(value / 100000).toStringAsFixed(2)} L';
    }
    return '₹${value.toStringAsFixed(2)}';
  }
}
