import 'package:flutter/material.dart';


import '../../../../core/utils/common_logger.dart';
import '../../models/heatmap.dart';

/// Pure heatmap layout template - handles header, legend, and overall structure
/// Extracted for better modularity and composition
class HeatmapLayoutTemplate extends StatelessWidget {
  const HeatmapLayoutTemplate({
    required this.data,
    required this.displayWidget,
    super.key,
    this.selectorWidget,
    this.title,
    this.subtitle,
    this.icon,
    this.showHeader = true,
    this.showLegend = true,
    this.showSelectors = true,
    this.headerActions,
    this.customHeader,
    this.padding,
    this.backgroundColor,
  });

  final HeatmapData data;
  final Widget displayWidget;
  final Widget? selectorWidget;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final bool showHeader;
  final bool showLegend;
  final bool showSelectors;
  final List<Widget>? headerActions;
  final Widget? customHeader;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    CommonLogger.debug(
      'HeatmapLayoutTemplate: rendering layout with header=$showHeader, legend=$showLegend, selectors=$showSelectors',
      tag: 'Heatmap.Layout',
    );

    return Container(
      color: backgroundColor,
      padding: padding ?? const EdgeInsets.all(8),
      child: Column(
        children: [
          // Selectors section
          if (showSelectors && selectorWidget != null) ...[
            selectorWidget!,
            const SizedBox(height: 12),
          ],

          // Main heatmap card
          Expanded(
            child: Card(
              elevation: 4,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header section
                    if (showHeader) ...[
                      customHeader ?? _buildHeader(context),
                      const SizedBox(height: 16),
                    ],

                    // Legend section
                    if (showLegend && data.configuration.showPerformance) ...[
                      _buildColorLegend(context),
                      const SizedBox(height: 16),
                    ],

                    // Main display content
                    Expanded(child: displayWidget),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final effectiveTitle = title ?? data.title;
    final effectiveSubtitle = subtitle ?? data.subtitle;

    return Row(
      children: [
        // Icon
        if (icon != null) ...[
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(width: 8),
        ],

        // Title and subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                effectiveTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (effectiveSubtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  effectiveSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),

        // Header actions
        if (headerActions != null && headerActions!.isNotEmpty) ...[
          const SizedBox(width: 8),
          Row(children: headerActions!),
        ],
      ],
    );
  }

  Widget _buildColorLegend(BuildContext context) {
    if (data.configuration.colorScheme != HeatmapColorSchemeType.performance) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Text('Performance: ', style: Theme.of(context).textTheme.bodySmall),
        Expanded(
          child: Row(
            children: [
              _buildLegendItem(context, 'Loss', Colors.red.shade300),
              const SizedBox(width: 16),
              _buildLegendItem(context, 'Neutral', Colors.grey.shade300),
              const SizedBox(width: 16),
              _buildLegendItem(context, 'Gain', Colors.green.shade300),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

/// Factory constructors for common layout configurations
extension HeatmapLayoutTemplateFactory on HeatmapLayoutTemplate {
  /// Create a minimal layout (no selectors, simple header)
  static HeatmapLayoutTemplate minimal({
    required HeatmapData data,
    required Widget displayWidget,
    String? title,
    IconData? icon,
  }) => HeatmapLayoutTemplate(
    data: data,
    displayWidget: displayWidget,
    title: title,
    icon: icon,
    showSelectors: false,
    showLegend: false,
  );

  /// Create a compact layout (compact selectors, minimal header)
  static HeatmapLayoutTemplate compact({
    required HeatmapData data,
    required Widget displayWidget,
    Widget? selectorWidget,
    String? title,
    IconData? icon,
  }) => HeatmapLayoutTemplate(
    data: data,
    displayWidget: displayWidget,
    selectorWidget: selectorWidget,
    title: title,
    icon: icon,
    showSelectors: selectorWidget != null,
    padding: const EdgeInsets.all(4),
  );

  /// Create a full layout (all features enabled)
  static HeatmapLayoutTemplate full({
    required HeatmapData data,
    required Widget displayWidget,
    Widget? selectorWidget,
    String? title,
    String? subtitle,
    IconData? icon,
    List<Widget>? headerActions,
  }) => HeatmapLayoutTemplate(
    data: data,
    displayWidget: displayWidget,
    selectorWidget: selectorWidget,
    title: title,
    subtitle: subtitle,
    icon: icon,
    showSelectors: selectorWidget != null,
    headerActions: headerActions,
    padding: const EdgeInsets.all(8),
  );

  /// Create a dashboard layout (optimized for dashboard widgets)
  static HeatmapLayoutTemplate dashboard({
    required HeatmapData data,
    required Widget displayWidget,
    Widget? selectorWidget,
    String? title,
    IconData? icon,
  }) => HeatmapLayoutTemplate(
    data: data,
    displayWidget: displayWidget,
    selectorWidget: selectorWidget,
    title: title,
    icon: icon,
    showSelectors: selectorWidget != null,
    showLegend: false,
    padding: const EdgeInsets.all(6),
  );
}
