import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:am_common/am_common.dart';
import 'package:am_design_system/am_design_system.dart' as ds;
import '../services/real_analysis_service.dart';
import '../models/analysis_models.dart';
import '../models/analysis_enums.dart';

/// Responsive performance chart widget with time frame and chart type selectors
class AnalysisPerformanceWidget extends StatefulWidget {
  const AnalysisPerformanceWidget({
    required this.portfolioId,
    this.initialTimeFrame = ds.TimeFrame.oneMonth,
    this.height,
    super.key,
  });

  final String portfolioId;
  final ds.TimeFrame initialTimeFrame;
  final double? height;

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
    final storage = SecureStorageService();
    final token = await storage.getAccessToken();
    _service = RealAnalysisService(authToken: token != null ? 'Bearer $token' : null);
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
      print('[Performance] Successfully loaded ${points.length} data points');
      
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
        final height = widget.height ?? (isMobile ? 280 : isTablet ? 260 : 250);
        final padding = isMobile ? 16.0 : 20.0;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Performance',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 16 : 18,
                      ),
                    ),
                  ),
                  if (_isLoading)
                    SizedBox(
                      width: isMobile ? 16 : 20,
                      height: isMobile ? 16 : 20,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              SizedBox(height: isMobile ? 10 : 12),
              // Controls: Time Frame + Chart Type
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ds.TimeFrameSelector.portfolio(
                          selectedTimeFrame: _selectedTimeFrame,
                          onTimeFrameChanged: _onTimeFrameChanged,
                          compact: true,
                        ),
                        const SizedBox(height: 8),
                        _buildChartTypeSelector(isMobile),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: ds.TimeFrameSelector.portfolio(
                            selectedTimeFrame: _selectedTimeFrame,
                            onTimeFrameChanged: _onTimeFrameChanged,
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildChartTypeSelector(isMobile),
                      ],
                    ),
              SizedBox(height: isMobile ? 12 : 16),
              Expanded(
                child: _buildContent(isMobile),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartTypeSelector(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minHeight: 44), // Touch target
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ChartType.values.map((type) {
          final isSelected = type == _chartType;
          final iconSize = isMobile ? 16.0 : 18.0;
          
          return GestureDetector(
            onTap: () => setState(() => _chartType = type),
            child: Container(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 36), // Touch target
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 12, 
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                type == ChartType.line
                    ? Icons.show_chart
                    : type == ChartType.area
                        ? Icons.area_chart_outlined
                        : Icons.bar_chart,
                size: iconSize,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(bool isMobile) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, 
              color: Theme.of(context).colorScheme.error, 
              size: isMobile ? 40 : 48,
            ),
            const SizedBox(height: 8),
            Text(
              'Error loading performance',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: isMobile ? 13 : 14,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      );
    }

    if (_dataPoints.isEmpty) {
      return Center(
        child: Text(
          'No performance data available',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: isMobile ? 13 : 14,
          ),
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

    if (_chartType == ChartType.bar) {
      return BarChart(
        BarChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              strokeWidth: 1,
            ),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: minY * 0.98,
          maxY: maxY * 1.02,
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
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: minY * 0.98,
        maxY: maxY * 1.02,
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
        lineTouchData: const LineTouchData(enabled: false),
      ),
    );
  }
}
