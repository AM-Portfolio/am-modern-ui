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
    this.compactHeader = false,
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

  /// Denser title row for mobile — no squeezed legend beside the title.
  final bool compactHeader;

  @override
  Widget build(BuildContext context) {
    CommonLogger.debug(
      'HeatmapLayoutTemplate: rendering layout with header=$showHeader, legend=$showLegend, selectors=$showSelectors',
      tag: 'Heatmap.Layout',
    );

    final cardPadding = compactHeader
        ? const EdgeInsets.fromLTRB(12, 10, 12, 12)
        : const EdgeInsets.all(16);

    return Container(
      color: backgroundColor,
      padding: padding ?? const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selectors section — uses intrinsic height only, never steals from heatmap.
          if (showSelectors && selectorWidget != null) ...[
            SizedBox(
              width: double.infinity,
              child: selectorWidget!,
            ),
            const SizedBox(height: 8),
          ],

          // Main heatmap card — takes all remaining vertical space.
          Expanded(
            child: Card(
              elevation: compactHeader ? 2 : 4,
              margin: EdgeInsets.zero,
              child: Padding(
                padding: cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section
                    if (showHeader) ...[
                      customHeader ?? _buildHeader(context),
                      SizedBox(height: compactHeader ? 8 : 12),
                    ],

                    // Main display content — fills remaining card space.
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
    final showInlineLegend =
        showLegend && data.configuration.showPerformance && !compactHeader;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (effectiveTitle.isNotEmpty)
          Text(
            effectiveTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: (compactHeader
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.titleLarge)
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        if (!compactHeader &&
            effectiveSubtitle != null &&
            effectiveSubtitle.isNotEmpty &&
            effectiveSubtitle != effectiveTitle) ...[
          if (effectiveTitle.isNotEmpty) const SizedBox(height: 4),
          Text(
            effectiveSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: compactHeader ? 20 : 24,
          ),
          SizedBox(width: compactHeader ? 8 : 8),
        ],
        Expanded(child: titleBlock),
        if (showInlineLegend) ...[
          const SizedBox(width: 8),
          Flexible(
            fit: FlexFit.loose,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: _buildColorLegend(context),
              ),
            ),
          ),
        ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Performance: ', style: Theme.of(context).textTheme.bodySmall),
        _buildLegendItem(context, 'Loss', Colors.red.shade300),
        const SizedBox(width: 16),
        _buildLegendItem(context, 'Neutral', Colors.grey.shade300),
        const SizedBox(width: 16),
        _buildLegendItem(context, 'Gain', Colors.green.shade300),
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
