import 'dart:ui';
import 'package:flutter/material.dart';

class PortfolioMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final bool? isPositive;
  final bool isHighlight;
  final bool compact;
  final String? tooltip;

  const PortfolioMetricCard({
    Key? key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    this.isPositive,
    this.isHighlight = false,
    this.compact = false,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use theme colors
    final cardColor = Theme.of(context).cardColor;
    final textTheme = Theme.of(context).textTheme;

    final verticalPadding = compact ? 12.0 : 16.0;
    final horizontalPadding = compact ? 12.0 : 16.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip ?? title,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            decoration: BoxDecoration(
              gradient: isHighlight
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accentColor.withValues(alpha: 0.8),
                        accentColor.withValues(alpha: 0.6),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cardColor.withValues(alpha: isDark ? 0.4 : 0.6),
                        cardColor.withValues(alpha: isDark ? 0.2 : 0.4),
                      ],
                    ),
              borderRadius: BorderRadius.circular(16), // Softer corners
              border: Border.all(
                color: isHighlight
                    ? Colors.white.withValues(alpha: 0.2)
                    : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHighlight
                      ? accentColor.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row: Title + Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: compact ? 10 : 11,
                          color: isHighlight
                              ? Colors.white.withValues(alpha: 0.85)
                              : Theme.of(
                                  context,
                                ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600, // Slightly bolder
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(compact ? 4 : 6),
                      decoration: BoxDecoration(
                        color: isHighlight
                            ? Colors.white.withValues(alpha: 0.2)
                            : accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        icon,
                        size: compact ? 12 : 14,
                        color: isHighlight ? Colors.white : accentColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 8 : 12),
                // Main Value
                Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: textTheme.headlineSmall?.copyWith(
                        fontSize: compact ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: isHighlight
                            ? Colors.white
                            : Theme.of(context).textTheme.bodyLarge?.color,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 6 : 8),
                // Subtitle with change indicator
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPositive != null) ...[
                      Icon(
                        isPositive! ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: compact ? 10 : 12,
                        color: isHighlight
                            ? Colors.white.withValues(alpha: 0.9)
                            : accentColor,
                      ),
                      const SizedBox(width: 2),
                    ],
                    Flexible(
                      child: Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: compact ? 9 : 11,
                          color: isHighlight
                              ? Colors.white.withValues(alpha: 0.75)
                              : ((isPositive != null)
                                    ? accentColor
                                    : Theme.of(context).textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.5)),
                          fontWeight: (isPositive != null && isPositive!) ? FontWeight.w600 : FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
