import 'package:flutter/material.dart';
import '../../../core/theme/app_colors_theme.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_type_scale.dart';
import '../../../core/theme/color_extensions.dart';

/// A single key-value metric displayed inside [AmEntityMobileCard].
class AmCardMetricItem {
  const AmCardMetricItem({
    required this.label,
    this.valueWidget,
    this.valueText,
    this.valueColor,
    this.isHighlighted = false,
    this.flex = 1,
  });

  /// Metric name/header (e.g. 'P/E', 'ROE %', 'P/B').
  final String label;

  /// Custom widget for the value (e.g. colored metric bar or rich text).
  final Widget? valueWidget;

  /// String value if [valueWidget] is not provided.
  final String? valueText;

  /// Text color for [valueText]. Defaults to [AppColorsTheme.textPrimary].
  final Color? valueColor;

  /// When true, highlights this metric tile with an accent border and background tint.
  final bool isHighlighted;

  /// Flex allocation when rendered in a row.
  final int flex;
}

/// Compact letter avatar with deterministic background tint based on text hash.
class AmLetterAvatar extends StatelessWidget {
  const AmLetterAvatar({
    super.key,
    required this.text,
    this.color,
    this.size = 36.0,
    this.borderRadius,
  });

  /// The text (e.g. stock symbol or company name) used to derive the initial.
  final String text;

  /// Explicit color override. If null, a deterministic color is chosen from a harmonious palette.
  final Color? color;

  /// Width and height of the avatar container. Defaults to 36.0.
  final double size;

  /// Custom border radius. Defaults to [AppRadii.button].
  final BorderRadius? borderRadius;

  static const List<Color> _palette = [
    Color(0xFF6C5DD3), // Purple
    Color(0xFF00B4D8), // Cyan
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Violet
    Color(0xFF3B82F6), // Blue
    Color(0xFF14B8A6), // Teal
  ];

  /// Deterministically derives a vibrant palette color from [text].
  static Color colorForText(String text) {
    if (text.isEmpty) return _palette.first;
    var hash = 0;
    for (final c in text.codeUnits) {
      hash = (hash + c) % _palette.length;
    }
    return _palette[hash];
  }

  /// Extracts the first uppercase letter or '?' if empty.
  static String initial(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? colorForText(text);
    final letter = initial(text);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.18),
        borderRadius: borderRadius ?? AppRadii.button,
      ),
      child: Text(
        letter,
        style: TextStyle(
          color: effectiveColor,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
          height: 1.0,
        ),
      ),
    );
  }
}

/// Compact badge pill used for statuses, tags (e.g. 'YOU', 'WIN', 'LOSS'), or % changes.
class AmMetricBadge extends StatelessWidget {
  const AmMetricBadge({
    super.key,
    required this.label,
    required this.color,
    this.isSolid = false,
    this.fontSize = AppTypeScale.xs,
    this.padding,
    this.borderRadius,
  });

  final String label;
  final Color color;
  final bool isSolid;
  final double fontSize;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm - 2,
            vertical: AppSpacing.xxs,
          ),
      decoration: BoxDecoration(
        color: isSolid ? color : color.withValues(alpha: 0.14),
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadii.xs),
        border: Border.all(
          color: color.withValues(alpha: isSolid ? 1.0 : 0.28),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSolid ? Colors.white : color,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          height: 1.1,
        ),
      ),
    );
  }
}

/// Standard mobile card for tabular data entities (peers, holdings, orders, recent activity).
///
/// Follows the modern Lumina aesthetic:
/// - Letter avatar leading.
/// - Primary symbol / name with subtitle and optional tags/badges.
/// - Right-aligned primary metric (e.g. Price) and secondary metric (e.g. Day change pill).
/// - Structured key-value metrics grid for remaining columns.
/// - Dual touch targets: [onHeaderTap] for stock selection and [onMetricsTap] / expansion toggle for metrics.
/// - Expandable metrics with smooth animation ("View more ratios" / "Show less").
class AmEntityMobileCard extends StatefulWidget {
  const AmEntityMobileCard({
    super.key,
    this.leading,
    required this.title,
    this.titleStyle,
    this.subtitle,
    this.titleBadge,
    this.primaryMetric,
    this.secondaryMetric,
    this.metrics = const [],
    this.additionalMetrics = const [],
    this.metricsColumns = 2,
    this.onTap,
    this.onHeaderTap,
    this.onMetricsTap,
    this.expandableMetrics = false,
    this.initiallyExpanded = false,
    this.expandLabel = 'View more ratios',
    this.collapseLabel = 'Show less',
    this.additionalMetricsTitle = 'Additional Ratios',
    this.isSelected = false,
    this.accentColor,
    this.cardColor,
    this.borderColor,
    this.padding,
  });

  /// Leading widget, typically [AmLetterAvatar].
  final Widget? leading;

  /// Primary title (e.g. Symbol or Company Name).
  final Widget title;

  /// Optional custom title style.
  final TextStyle? titleStyle;

  /// Subtitle text (e.g. full company name or date).
  final String? subtitle;

  /// Optional badge displayed next to the title (e.g. [AmMetricBadge] for 'YOU').
  final Widget? titleBadge;

  /// Primary top-right metric (e.g. Price).
  final Widget? primaryMetric;

  /// Secondary top-right metric (e.g. Day change pill).
  final Widget? secondaryMetric;

  /// Structured fundamental metrics displayed in the primary grid below the header.
  final List<AmCardMetricItem> metrics;

  /// Additional fundamental metrics displayed in the expandable drawer.
  final List<AmCardMetricItem> additionalMetrics;

  /// Number of columns in the metrics grid (defaults to 2, supports up to 4).
  final int metricsColumns;

  /// Fallback tap callback for the entire card.
  final VoidCallback? onTap;

  /// Specific tap callback for the header row (e.g. navigate to stock detail or fundamental analysis).
  final VoidCallback? onHeaderTap;

  /// Specific tap callback for the metrics body. Defaults to expanding/collapsing when [expandableMetrics] is true.
  final VoidCallback? onMetricsTap;

  /// When true, displays an expandable toggle ("View more ratios") for [additionalMetrics].
  final bool expandableMetrics;

  /// Initial expansion state (e.g. when an active sort column belongs to additional metrics).
  final bool initiallyExpanded;

  /// Button label when collapsed. Defaults to 'View more ratios'.
  final String expandLabel;

  /// Button label when expanded. Defaults to 'Show less'.
  final String collapseLabel;

  /// Section heading above [additionalMetrics]. Defaults to 'Additional Ratios'.
  final String? additionalMetricsTitle;

  /// When true, renders a highlighted border indicating selection.
  final bool isSelected;

  /// Accent color used for highlighted borders and active metric tiles.
  final Color? accentColor;

  /// Card surface color override. Defaults to [AppColorsTheme.cardSurface].
  final Color? cardColor;

  /// Card border color override. Defaults to [AppColorsTheme.border].
  final Color? borderColor;

  /// Internal padding for the card. Defaults to [AppSpacing.sm + 4].
  final EdgeInsetsGeometry? padding;

  @override
  State<AmEntityMobileCard> createState() => _AmEntityMobileCardState();
}

class _AmEntityMobileCardState extends State<AmEntityMobileCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant AmEntityMobileCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initiallyExpanded != oldWidget.initiallyExpanded && widget.initiallyExpanded) {
      _isExpanded = true;
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectiveAccent = widget.accentColor ?? colors.actionPrimaryBg;
    final bg = widget.cardColor ?? colors.cardSurface;
    final effectiveBorderColor = widget.borderColor ??
        (widget.isSelected
            ? effectiveAccent
            : colors.border.withValues(alpha: context.isDark ? 0.35 : 0.7));

    final hasMetrics = widget.metrics.isNotEmpty;
    final hasAdditional = widget.additionalMetrics.isNotEmpty;
    final isExpandable = widget.expandableMetrics && hasAdditional;

    final headerTap = widget.onHeaderTap ?? widget.onTap;
    final metricsTap = widget.onMetricsTap ?? (isExpandable ? _toggleExpanded : widget.onTap);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.card,
        border: Border.all(
          color: effectiveBorderColor,
          width: widget.isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isSelected
                ? effectiveAccent.withValues(alpha: 0.12)
                : context.shadow(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppRadii.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: [Avatar] [Title + Badge + Subtitle] [Price + Day Chg]
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: headerTap,
                borderRadius: hasMetrics ? const BorderRadius.vertical(top: Radius.circular(AppRadii.lg)) : AppRadii.card,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm + 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (widget.leading != null) ...[
                        widget.leading!,
                        const SizedBox(width: AppSpacing.sm + 2),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(child: widget.title),
                                if (widget.titleBadge != null) ...[
                                  const SizedBox(width: AppSpacing.xs + 2),
                                  widget.titleBadge!,
                                ],
                              ],
                            ),
                            if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xxs + 1),
                              Text(
                                widget.subtitle!,
                                style: TextStyle(
                                  fontSize: AppTypeScale.xs,
                                  color: colors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.primaryMetric != null || widget.secondaryMetric != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (widget.primaryMetric != null) widget.primaryMetric!,
                            if (widget.secondaryMetric != null) ...[
                              const SizedBox(height: AppSpacing.xxs + 2),
                              widget.secondaryMetric!,
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Metrics Section (Body)
            if (hasMetrics || hasAdditional) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4),
                height: 1,
                color: colors.border.withValues(alpha: 0.35),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: metricsTap,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppRadii.lg)),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm + 4,
                      AppSpacing.sm,
                      AppSpacing.sm + 4,
                      AppSpacing.xs + 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Primary Metrics Grid
                        if (hasMetrics)
                          _buildMetricsGrid(context, effectiveAccent, widget.metrics),

                        // If collapsed, show "View more ratios" button
                        if (isExpandable && !_isExpanded) ...[
                          const SizedBox(height: 6),
                          Center(
                            child: InkWell(
                              onTap: _toggleExpanded,
                              borderRadius: BorderRadius.circular(AppRadii.xs),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.expandLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: effectiveAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 16,
                                      color: effectiveAccent,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],

                        // Expandable Animated Section
                        if (isExpandable)
                          AnimatedCrossFade(
                            duration: const Duration(milliseconds: 220),
                            firstCurve: Curves.easeOutCubic,
                            secondCurve: Curves.easeInCubic,
                            sizeCurve: Curves.easeOutCubic,
                            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                            firstChild: const SizedBox(width: double.infinity, height: 0),
                            secondChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.additionalMetricsTitle != null &&
                                    widget.additionalMetricsTitle!.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                                    child: Text(
                                      widget.additionalMetricsTitle!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                        color: colors.textSecondary.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),
                                ],
                                _buildMetricsGrid(context, effectiveAccent, widget.additionalMetrics),
                                const SizedBox(height: 6),
                                Center(
                                  child: InkWell(
                                    onTap: _toggleExpanded,
                                    borderRadius: BorderRadius.circular(AppRadii.xs),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            widget.collapseLabel,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: effectiveAccent,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.keyboard_arrow_up,
                                            size: 16,
                                            color: effectiveAccent,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, Color accent, List<AmCardMetricItem> itemsList) {
    final colors = context.colors;
    final int cols = widget.metricsColumns.clamp(1, 4);
    final List<Widget> rows = [];

    for (int i = 0; i < itemsList.length; i += cols) {
      final end = (i + cols).clamp(0, itemsList.length);
      final chunk = itemsList.sublist(i, end);

      final rowChildren = <Widget>[];

      for (int c = 0; c < chunk.length; c++) {
        final item = chunk[c];
        final isHi = item.isHighlighted;

        rowChildren.add(
          Expanded(
            flex: item.flex,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs + 2,
                vertical: AppSpacing.xxs + 2,
              ),
              decoration: BoxDecoration(
                color: isHi
                    ? accent.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.xs),
                border: isHi
                    ? Border.all(color: accent.withValues(alpha: 0.45), width: 1)
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isHi ? FontWeight.w700 : FontWeight.w600,
                      letterSpacing: 0.4,
                      color: isHi
                          ? accent
                          : colors.textSecondary.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (item.valueWidget != null)
                    item.valueWidget!
                  else
                    Text(
                      item.valueText ?? '—',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isHi ? FontWeight.w700 : FontWeight.w600,
                        color: item.valueColor ?? colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        );

        // Add spacer between columns within the row
        if (c < chunk.length - 1) {
          rowChildren.add(const SizedBox(width: AppSpacing.xs));
        }
      }

      // If chunk has fewer items than cols, pad with empty Expanded
      if (chunk.length < cols) {
        for (int p = 0; p < (cols - chunk.length); p++) {
          rowChildren.add(const SizedBox(width: AppSpacing.xs));
          rowChildren.add(const Expanded(child: SizedBox.shrink()));
        }
      }

      if (rows.isNotEmpty) {
        rows.add(const SizedBox(height: AppSpacing.xs));
      }
      rows.add(Row(children: rowChildren));
    }

    return Column(children: rows);
  }
}
