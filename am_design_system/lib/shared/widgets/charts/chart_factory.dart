import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
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
  final List<ChartLineData>? lines;

  const ChartFactory({
    required this.type,
    required this.data,
    super.key,
    this.config = const CommonChartConfig(),
    this.primaryColor,
    this.height = 300,
    this.lines,
  });

  /// Factory constructor for Line Chart
  factory ChartFactory.line({
    required List<CommonChartDataPoint> data,
    CommonChartConfig config = const CommonChartConfig(),
    Color? color,
    double height = 300,
    List<ChartLineData>? lines,
  }) {
    return ChartFactory(
      type: ChartType.line,
      data: data,
      config: config,
      primaryColor: color,
      height: height,
      lines: lines,
    );
  }

  /// Factory constructor for Area Chart
  factory ChartFactory.area({
    required List<CommonChartDataPoint> data,
    CommonChartConfig config = const CommonChartConfig(),
    Color? color,
    double height = 300,
    List<ChartLineData>? lines,
  }) {
    return ChartFactory(
      type: ChartType.area,
      data: data,
      config: config,
      primaryColor: color,
      height: height,
      lines: lines,
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
    if (data.isEmpty && (lines == null || lines!.isEmpty)) {
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
    final isDark = theme.brightness == Brightness.dark;
    
    final bool hasMultiLines = lines != null && lines!.isNotEmpty;

    // Calculate minY and maxY dynamically with 15% padding so the line doesn't hit the ceiling
    double? calculatedMinY;
    double? calculatedMaxY;
    if (data.isNotEmpty || hasMultiLines) {
      double minVal = double.infinity;
      double maxVal = double.negativeInfinity;

      void processPoints(List<CommonChartDataPoint> pts) {
        for (var p in pts) {
          if (p.y < minVal) minVal = p.y;
          if (p.y > maxVal) maxVal = p.y;
        }
      }

      if (hasMultiLines) {
        for (var l in lines!) processPoints(l.points);
      } else {
        processPoints(data);
      }

      if (minVal != double.infinity && maxVal != double.negativeInfinity) {
        final double range = (maxVal - minVal).abs();
        final double padding = range == 0 ? maxVal.abs() * 0.15 : range * 0.15;
        
        calculatedMinY = minVal - padding;
        calculatedMaxY = maxVal + padding;

        // If all values are non-negative, don't let minY go below 0 (unless we want to show negative drops)
        if (minVal >= 0 && calculatedMinY < 0) {
          calculatedMinY = 0;
        }
      }
    }

    // Resolve bars: either map multi-lines or create single bar from data
    final List<LineChartBarData> bars = hasMultiLines
        ? lines!.map((lineData) => LineChartBarData(
            spots: lineData.points.map((d) => FlSpot(d.x, d.y)).toList(),
            isCurved: true,
            color: lineData.color ?? color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          )).toList()
        : [
            LineChartBarData(
              spots: data.map((d) => FlSpot(d.x, d.y)).toList(),
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: type == ChartType.area,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ];

    final chart = LineChart(
      LineChartData(
        minY: calculatedMinY,
        maxY: calculatedMaxY,
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
              interval: 1, // Fix repeating dates
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                final List<CommonChartDataPoint> activePoints = hasMultiLines
                    ? lines!.first.points
                    : data;
                if (index >= 0 && index < activePoints.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      activePoints[index].xLabel ?? '',
                      style: TextStyle(fontSize: 10, color: theme.hintColor),
                    ),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 30,
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 16, // Acts as internal top padding to prevent left Y-axis labels from clipping
              getTitlesWidget: (value, meta) => const SizedBox.shrink(),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                // Smart formatter: if max value is very small (like %), show decimals
                String text;
                if (value.abs() < 10) {
                  text = value.toStringAsFixed(2);
                } else if (value.abs() >= 1e7) {
                  text = '${(value / 1e7).toStringAsFixed(2)}Cr';
                } else if (value.abs() >= 1e5) {
                  text = '${(value / 1e5).toStringAsFixed(2)}L';
                } else {
                  text = value.toInt().toString();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    text,
                    style: TextStyle(fontSize: 10, color: theme.hintColor),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: bars,
        lineTouchData: LineTouchData(
          enabled: config.showTooltips,
          touchTooltipData: LineTouchTooltipData(
            // [Interactive] Lock to top boundary when flag is set (Google Finance style)
            showOnTopOfTheChartBoxArea: config.lockTooltipToTop,
            tooltipMargin: config.lockTooltipToTop ? 8.0 : 16.0,
            getTooltipColor: config.lockTooltipToTop
                ? (_) => Colors.transparent
                : (_) => AppColors.darkBackground.withOpacity(0.9),
            tooltipBorder: config.lockTooltipToTop
                ? BorderSide.none
                : const BorderSide(color: Colors.transparent),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final List<CommonChartDataPoint> activePoints = hasMultiLines
                    ? lines![spot.barIndex].points
                    : data;
                final point = activePoints[spot.spotIndex];
                final String lineLabel = hasMultiLines
                    ? '${lines![spot.barIndex].label}: '
                    : '';
                // [Interactive] Color tooltip text to match the line color when top-locked
                final Color textColor = config.lockTooltipToTop && hasMultiLines
                    ? (lines![spot.barIndex].color ?? Colors.white)
                    : Colors.white;
                final Color dateColor = config.lockTooltipToTop
                    ? (isDark ? Colors.white60 : Colors.black54)
                    : Colors.white70;
                return LineTooltipItem(
                  '$lineLabel${point.yLabel ?? point.y.toString()}\n',
                  TextStyle(color: textColor, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: point.xLabel ?? '',
                      style: TextStyle(color: dateColor, fontSize: 10),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
      ),
      duration: config.animate ? config.animationDuration : Duration.zero,
      curve: Curves.easeInOutCubic,
    );

    // [Interactive] Wrap with zoom controls when enableZoom is true
    if (config.enableZoom) {
      return _ZoomableChartWrapper(
        initialZoomScale: config.initialZoomScale,
        child: chart,
      );
    }

    return chart;
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

// ─────────────────────────────────────────────────────────────────────────────
// Private Zoom Wrapper
// Used internally by ChartFactory when config.enableZoom == true.
// Wraps any chart child with Zoom-In / Zoom-Out buttons and Ctrl+Wheel support.
// ─────────────────────────────────────────────────────────────────────────────
class _ZoomableChartWrapper extends StatefulWidget {
  final Widget child;
  final double initialZoomScale;

  const _ZoomableChartWrapper({
    required this.child,
    this.initialZoomScale = 1.0,
  });

  @override
  State<_ZoomableChartWrapper> createState() => _ZoomableChartWrapperState();
}

class _ZoomableChartWrapperState extends State<_ZoomableChartWrapper> {
  late double _zoomScale;

  static const double _minZoom = 0.2;
  static const double _maxZoom = 3.0;
  static const double _zoomStep = 0.2;

  @override
  void initState() {
    super.initState();
    _zoomScale = widget.initialZoomScale.clamp(_minZoom, _maxZoom);
  }

  void _adjustZoom(double delta) {
    setState(() {
      _zoomScale = (_zoomScale + delta).clamp(_minZoom, _maxZoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controlBg = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final controlFg = isDark ? Colors.white70 : Colors.black54;

    return Listener(
      // Ctrl + Mouse Wheel to zoom
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          final isCtrl = HardwareKeyboard.instance.logicalKeysPressed
              .any((k) => k == LogicalKeyboardKey.controlLeft || k == LogicalKeyboardKey.controlRight);
          if (isCtrl) {
            final delta = event.scrollDelta.dy < 0 ? _zoomStep : -_zoomStep;
            _adjustZoom(delta);
          }
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Zoom control bar
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.max,
            children: [
              _ZoomButton(
                icon: Icons.remove,
                onTap: () => _adjustZoom(-_zoomStep),
                bg: controlBg,
                fg: controlFg,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${(_zoomScale * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: controlFg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _ZoomButton(
                icon: Icons.add,
                onTap: () => _adjustZoom(_zoomStep),
                bg: controlBg,
                fg: controlFg,
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Chart scaled by zoom
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                width: MediaQuery.of(context).size.width * _zoomScale,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;
  final Color fg;

  const _ZoomButton({
    required this.icon,
    required this.onTap,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 14, color: fg),
      ),
    );
  }
}
