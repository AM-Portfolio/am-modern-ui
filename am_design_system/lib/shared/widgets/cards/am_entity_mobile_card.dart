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
/// - Structured key-value metrics grid for all remaining columns.
/// - Full card touch target with ripple.
class AmEntityMobileCard extends StatelessWidget {
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
    this.metricsColumns = 2,
    this.onTap,
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

  /// Structured fundamental metrics displayed in a grid below the header.
  final List<AmCardMetricItem> metrics;

  /// Number of columns in the metrics grid (defaults to 2).
  final int metricsColumns;

  /// Tap callback for the entire card.
  final VoidCallback? onTap;

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
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectiveAccent = accentColor ?? colors.actionPrimaryBg;
    final bg = cardColor ?? colors.cardSurface;
    final effectiveBorderColor = borderColor ??
        (isSelected
            ? effectiveAccent
            : colors.border.withValues(alpha: context.isDark ? 0.35 : 0.7));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppSpacing.sm + 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadii.card,
            border: Border.all(
              color: effectiveBorderColor,
              width: isSelected ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? effectiveAccent.withValues(alpha: 0.12)
                    : context.shadow(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: [Avatar] [Title + Badge + Subtitle] [Price + Day Chg]
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AppSpacing.sm + 2),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(child: title),
                            if (titleBadge != null) ...[
                              const SizedBox(width: AppSpacing.xs + 2),
                              titleBadge!,
                            ],
                          ],
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xxs + 1),
                          Text(
                            subtitle!,
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
                  if (primaryMetric != null || secondaryMetric != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (primaryMetric != null) primaryMetric!,
                        if (secondaryMetric != null) ...[
                          const SizedBox(height: AppSpacing.xxs + 2),
                          secondaryMetric!,
                        ],
                      ],
                    ),
                  ],
                ],
              ),

              // Metrics Grid (Body)
              if (metrics.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  height: 1,
                  color: colors.border.withValues(alpha: 0.35),
                ),
                _buildMetricsGrid(context, effectiveAccent),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, Color accent) {
    final colors = context.colors;
    final int cols = metricsColumns.clamp(1, 4);
    final List<Widget> rows = [];

    for (int i = 0; i < metrics.length; i += cols) {
      final end = (i + cols).clamp(0, metrics.length);
      final chunk = metrics.sublist(i, end);

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
