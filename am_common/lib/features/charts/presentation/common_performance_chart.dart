import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

enum ChartFormat { primary, secondary }

class CommonPerformanceChart extends StatefulWidget {
  final String title;
  final List<CommonChartDataPoint> primaryData;
  final List<CommonChartDataPoint>? secondaryData;
  final List<ChartLineData>? lines; // Multi-line comparison option
  
  // Custom labels for the toggle buttons
  final String primaryToggleLabel;
  final String secondaryToggleLabel;

  // External state synchronization hooks
  final ChartFormat? externalFormat;
  final ValueChanged<ChartFormat>? onFormatChanged;

  // Visual customisation
  final Color? chartColor;
  final double height;
  final bool showGrid;
  final bool enableScrolling;
  final double minPointWidth; // Pixel spacing per point when scrolling is enabled
  final CommonChartConfig? config;
  final bool useCard;
  final bool isAreaChart;

  const CommonPerformanceChart({
    super.key,
    required this.title,
    required this.primaryData,
    this.secondaryData,
    this.lines,
    this.primaryToggleLabel = '\$',
    this.secondaryToggleLabel = '%',
    this.externalFormat,
    this.onFormatChanged,
    this.chartColor,
    this.height = 250,
    this.showGrid = false,
    this.enableScrolling = true,
    this.minPointWidth = 40.0,
    this.config,
    this.useCard = true,
    this.isAreaChart = false,
  });

  @override
  State<CommonPerformanceChart> createState() => _CommonPerformanceChartState();
}

class _CommonPerformanceChartState extends State<CommonPerformanceChart> {
  ChartFormat _internalFormat = ChartFormat.primary;

  @override
  Widget build(BuildContext context) {
    final bool showToggle = widget.secondaryData != null;
    final ChartFormat activeFormat = widget.externalFormat ?? _internalFormat;

    final activeData = (activeFormat == ChartFormat.secondary && showToggle)
        ? widget.secondaryData!
        : widget.primaryData;

    final bool hasMultiLines = widget.lines != null && widget.lines!.isNotEmpty;
    final int dataLength = hasMultiLines ? widget.lines!.first.points.length : activeData.length;

    Widget content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.only(top: showToggle ? 40.0 : 16.0, right: 0.0), // Added spacing here!
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double calculatedWidth = dataLength * widget.minPointWidth;
                    final bool needsScroll = widget.enableScrolling && (calculatedWidth > constraints.maxWidth);
                    
                    final double chartWidth = needsScroll ? calculatedWidth : constraints.maxWidth;

                    Widget chartWidget = SizedBox(
                      width: chartWidth,
                      height: widget.height,
                      child: widget.isAreaChart 
                        ? ChartFactory.area(
                            data: activeData,
                            lines: widget.lines,
                            config: widget.config ?? CommonChartConfig(
                              showGrid: widget.showGrid,
                              showTitles: true,
                              showLegend: false,
                              showTooltips: true,
                            ),
                            color: widget.chartColor ?? AppColors.primary,
                          )
                        : ChartFactory.line(
                            data: activeData,
                            lines: widget.lines,
                            config: widget.config ?? CommonChartConfig(
                              showGrid: widget.showGrid,
                              showTitles: true,
                              showLegend: false,
                              showTooltips: true,
                            ),
                            color: widget.chartColor ?? AppColors.primary,
                          ),
                    );

                    if (needsScroll) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: chartWidget,
                      );
                    }

                    return chartWidget;
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.title.isNotEmpty)
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                ],
              ),
              if (showToggle && !hasMultiLines)
                Positioned(
                  top: 0,
                  right: 0,
                  child: AppSegmentedControl<ChartFormat>(
                    selectedValue: activeFormat,
                    children: {
                      ChartFormat.primary: widget.primaryToggleLabel,
                      ChartFormat.secondary: widget.secondaryToggleLabel,
                    },
                    onValueChanged: (val) {
                      if (widget.onFormatChanged != null) {
                        widget.onFormatChanged!(val);
                      } else {
                        setState(() => _internalFormat = val);
                      }
                    },
                  ),
                ),
            ],
          ),
          if (hasMultiLines) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: widget.lines!.map((line) {
                final Color bulletColor = line.color ?? widget.chartColor ?? AppColors.primary;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: bulletColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      line.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ],
      );

    return widget.useCard ? AppCard(child: content) : content;
  }
}
