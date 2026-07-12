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
  final void Function(double min, double max)? onMinMaxCalculated;

  const ChartFactory({
    required this.type,
    required this.data,
    super.key,
    this.config = const CommonChartConfig(),
    this.primaryColor,
    this.height = 300,
    this.lines,
    this.onMinMaxCalculated,
  });

  /// Factory constructor for Line Chart
  factory ChartFactory.line({
    required List<CommonChartDataPoint> data,
    CommonChartConfig config = const CommonChartConfig(),
    Color? color,
    double height = 300,
    List<ChartLineData>? lines,
    void Function(double, double)? onMinMaxCalculated,
  }) {
    return ChartFactory(
      type: ChartType.line,
      data: data,
      config: config,
      primaryColor: color,
      height: height,
      lines: lines,
      onMinMaxCalculated: onMinMaxCalculated,
    );
  }

  /// Factory constructor for Area Chart
  factory ChartFactory.area({
    required List<CommonChartDataPoint> data,
    CommonChartConfig config = const CommonChartConfig(),
    Color? color,
    double height = 300,
    List<ChartLineData>? lines,
    void Function(double, double)? onMinMaxCalculated,
  }) {
    return ChartFactory(
      type: ChartType.area,
      data: data,
      config: config,
      primaryColor: color,
      height: height,
      lines: lines,
      onMinMaxCalculated: onMinMaxCalculated,
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
          if (p.y.isNaN || p.y.isInfinite) continue; // skip NaN/gap padding points
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
        if (minVal >= 0 && calculatedMinY! < 0) {
          calculatedMinY = 0;
        }
      }
    } // end of: if (data.isNotEmpty || hasMultiLines)
    
    if (onMinMaxCalculated != null && calculatedMinY != null && calculatedMaxY != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onMinMaxCalculated!(calculatedMinY!, calculatedMaxY!);
      });
    }

    double? calculatedYInterval;
    if (calculatedMinY != null && calculatedMaxY != null) {
      final double range = calculatedMaxY! - calculatedMinY!;
      if (range > 0) {
        if (range <= 10) calculatedYInterval = 2;
        else if (range <= 50) calculatedYInterval = 10;
        else if (range <= 100) calculatedYInterval = 20;
        else if (range <= 500) calculatedYInterval = 100;
        else if (range <= 1000) calculatedYInterval = 200;
        else if (range <= 5000) calculatedYInterval = 1000;
        else if (range <= 10000) calculatedYInterval = 2000;
        else if (range <= 50000) calculatedYInterval = 10000;
        else if (range <= 100000) calculatedYInterval = 20000;
        else calculatedYInterval = range / 5;
      }
    }

    // Resolve bars: either map multi-lines or create single bar from data
    final List<LineChartBarData> bars = hasMultiLines
        ? lines!.map((lineData) => LineChartBarData(
            spots: lineData.points.map((d) => d.y.isNaN ? FlSpot.nullSpot : FlSpot(d.x, d.y)).toList(),
            isCurved: true,
            color: lineData.color ?? color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) {
                final index = barData.spots.indexOf(spot);
                if (barData.spots.length <= 1) return true;
                final prev = index > 0 ? barData.spots[index - 1] : null;
                final next = index < barData.spots.length - 1 ? barData.spots[index + 1] : null;
                final isPrevNull = prev == null || prev.y.isNaN || prev == FlSpot.nullSpot;
                final isNextNull = next == null || next.y.isNaN || next == FlSpot.nullSpot;
                return isPrevNull && isNextNull;
              },
            ),
          )).toList()
        : [
            LineChartBarData(
              spots: data.map((d) => d.y.isNaN ? FlSpot.nullSpot : FlSpot(d.x, d.y)).toList(),
              isCurved: true,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, barData) {
                  final index = barData.spots.indexOf(spot);
                  if (barData.spots.length <= 1) return true;
                  final prev = index > 0 ? barData.spots[index - 1] : null;
                  final next = index < barData.spots.length - 1 ? barData.spots[index + 1] : null;
                  final isPrevNull = prev == null || prev.y.isNaN || prev == FlSpot.nullSpot;
                  final isNextNull = next == null || next.y.isNaN || next == FlSpot.nullSpot;
                  return isPrevNull && isNextNull;
                },
              ),
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

    final int dataLength = hasMultiLines ? lines!.first.points.length : data.length;
    double calculatedInterval = (dataLength / 6).ceil().toDouble();
    if (calculatedInterval < 1) calculatedInterval = 1;

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
              interval: config.xInterval ?? calculatedInterval, // Dynamically space out dates to prevent overlap
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                final List<CommonChartDataPoint> activePoints = hasMultiLines
                    ? lines!.first.points
                    : data;
                if (index >= 0 && index < activePoints.length) {
                  return Text(
                    activePoints[index].xLabel ?? '',
                    style: TextStyle(fontSize: 10, color: theme.hintColor),
                  );
                }
                return const SizedBox();
              },
              reservedSize: 14,
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
              interval: calculatedYInterval, // Use calculated interval for clean spacing
              reservedSize: 48,
              getTitlesWidget: (value, meta) {
                // Hide exact min/max if they don't align with our interval to prevent overlapping labels
                if (calculatedYInterval != null && (value == calculatedMinY || value == calculatedMaxY)) {
                  if ((value % calculatedYInterval!) != 0) {
                    return const SizedBox.shrink();
                  }
                }
                
                // Smart formatter: cleanly format 0, and show decimals for small non-zero numbers
                String text;
                if (config.formatYLabel != null) {
                  text = config.formatYLabel!(value);
                } else if (value == 0) {
                  text = '0';
                } else if (value.abs() < 10) {
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
          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: Colors.white.withOpacity(0.3),
                  strokeWidth: 1.5,
                  dashArray: [4, 4],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 5,
                      color: barData.color ?? theme.primaryColor,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
              );
            }).toList();
          },
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
                    : (hasMultiLines ? (lines![spot.barIndex].color ?? Colors.white) : Colors.white);
                final Color dateColor = config.lockTooltipToTop
                    ? (isDark ? Colors.white60 : Colors.black54)
                    : Colors.white70;
                
                // If locked to top, we might want a different layout, but for now just show date first
                return LineTooltipItem(
                  '${point.xLabel ?? ''}\n',
                  TextStyle(color: dateColor, fontSize: 10),
                  children: [
                    TextSpan(
                      text: '$lineLabel${point.yLabel ?? point.y.toString()}',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
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
        onZoomChanged: config.onZoomChanged,
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
  final void Function(double zoomScale, void Function(double) adjustZoom)? onZoomChanged;

  const _ZoomableChartWrapper({
    required this.child,
    this.initialZoomScale = 1.0,
    this.onZoomChanged,
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
    // Notify parent on init so it can build its own controls
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onZoomChanged?.call(_zoomScale, _adjustZoom);
    });
  }

  void _adjustZoom(double delta) {
    setState(() {
      _zoomScale = (_zoomScale + delta).clamp(_minZoom, _maxZoom);
    });
    // Notify parent of new zoom scale and the adjustZoom callback
    widget.onZoomChanged?.call(_zoomScale, _adjustZoom);
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            child: SizedBox(
              width: constraints.maxWidth * _zoomScale,
              child: widget.child,
            ),
          );
        },
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
