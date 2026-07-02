import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

enum ChartFormat { primary, secondary }

class CommonPerformanceChart extends StatefulWidget {
  final String title;
  final List<CommonChartDataPoint> primaryData;
  final List<CommonChartDataPoint>? secondaryData;
  
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

  const CommonPerformanceChart({
    super.key,
    required this.title,
    required this.primaryData,
    this.secondaryData,
    this.primaryToggleLabel = '\$',
    this.secondaryToggleLabel = '%',
    this.externalFormat,
    this.onFormatChanged,
    this.chartColor,
    this.height = 250,
    this.showGrid = false,
    this.enableScrolling = true,
    this.minPointWidth = 40.0,
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (showToggle)
                AppSegmentedControl<ChartFormat>(
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
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final double calculatedWidth = activeData.length * widget.minPointWidth;
              final bool needsScroll = widget.enableScrolling && (calculatedWidth > constraints.maxWidth);
              
              final double chartWidth = needsScroll ? calculatedWidth : constraints.maxWidth;

              Widget chartWidget = SizedBox(
                width: chartWidth,
                height: widget.height,
                child: ChartFactory.line(
                  data: activeData,
                  config: CommonChartConfig(
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
        ],
      ),
    );
  }
}
