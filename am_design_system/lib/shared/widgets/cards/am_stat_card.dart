
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:am_design_system/core/contracts/design_contract.dart';
import 'package:am_design_system/core/config/design_system_provider.dart';



/// Semantic types for Stat Cards.
/// Dictates the visual style without exposing raw colors.
enum StatType {
  neutral,
  positive,
  negative,
  accent,
}

/// A standardized Statistical Card component.
/// 
/// Follows the "Design Contract" architecture:
/// - Visuals are controlled by [type].
/// - Overrides are only allowed via [overrideContract].
class AmStatCard extends StatelessWidget {
  const AmStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.progress,
    this.type = StatType.neutral,
    this.overrideContract,
    this.onTap,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final double? progress; // 0.0 to 1.0
  final StatType type;
  final VoidCallback? onTap;

  /// Optional design override. Use strict contracts only when necessary.
  final ContainerStyleOverride? overrideContract;

  @override
  Widget build(BuildContext context) {
    // 1. Resolve Semantic Colors based on Type & Theme
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Get Design Config
    final config = DesignSystemProvider.of(context);
    
    Color valueColor;
    Color iconBgColor;
    Color progressColor;

    switch (type) {
      case StatType.positive:
        valueColor = const Color(0xFF00B894);
        iconBgColor = const Color(0xFF00B894).withOpacity(0.1);
        progressColor = const Color(0xFF00B894);
        break;
      case StatType.negative:
        valueColor = const Color(0xFFFF7675);
        iconBgColor = const Color(0xFFFF7675).withOpacity(0.1);
        progressColor = const Color(0xFFFF7675);
        break;
      case StatType.accent:
        valueColor = config.primaryColor; // Use config primary
        iconBgColor = config.primaryColor.withOpacity(0.1);
        progressColor = config.primaryColor;
        break;
      case StatType.neutral:
      default:
        valueColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
        iconBgColor = theme.dividerColor.withOpacity(0.1);
        progressColor = config.primaryColor;
        break;
    }

    // 2. Apply Standard Styles (or Overrides)
    final decoration = BoxDecoration(
      color: overrideContract?.backgroundColor ?? theme.cardTheme.color ?? theme.cardColor,
      borderRadius: overrideContract?.borderRadius ?? BorderRadius.circular(config.defaultRadius), // Use config radius
      boxShadow: overrideContract?.boxShadow ?? [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
      border: overrideContract?.border ?? Border.all(
        color: theme.dividerColor.withOpacity(0.1),
      ),
    );

    Widget cardContent = Container(
      decoration: decoration,
      child: Padding(
        padding: overrideContract?.padding ?? const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.info_outline, size: 14, color: theme.disabledColor),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        value,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: valueColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: type == StatType.neutral ? config.primaryColor : valueColor,
                    ),
                  ),
              ],
            ),
            if (subtitle != null || progress != null) ...[
              const SizedBox(height: 16),
              if (progress != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: theme.canvasColor,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              if (subtitle != null)
                Padding(
                  padding: EdgeInsets.only(top: progress != null ? 8 : 0),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: type == StatType.positive
                          ? const Color(0xFF00B894)
                          : (type == StatType.negative)
                              ? const Color(0xFFFF7675)
                              : theme.textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: overrideContract?.borderRadius as BorderRadius? ?? BorderRadius.circular(config.defaultRadius),
        child: cardContent,
      );
    }

    return cardContent.animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
  }
}
