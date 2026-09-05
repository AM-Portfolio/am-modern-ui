import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

import '../../utils/basket_responsive.dart';

class FpStatChip {
  final String label;
  final String value;
  final Color valueColor;

  const FpStatChip({
    required this.label,
    required this.value,
    required this.valueColor,
  });
}

class FpPanelHeader extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String constituentsBadge;
  final List<FpStatChip>? chips;

  const FpPanelHeader({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.constituentsBadge,
    this.chips,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = BasketResponsive.useCompactPreview(context);
    final pad = compact ? AppSpacing.md : AppSpacing.lg;
    final iconSize = compact ? 18.0 : 24.0;
    final iconPad = compact ? 8.0 : 12.0;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: (compact
                  ? theme.textTheme.titleSmall
                  : theme.textTheme.titleMedium)
              ?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                  fontSize: compact ? 11 : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (constituentsBadge.trim().isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: context.colors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  constituentsBadge,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );

    Widget chipRow(List<FpStatChip> list) {
      return Wrap(
        spacing: compact ? 6 : 8,
        runSpacing: 6,
        children: list.map((chip) {
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 12,
              vertical: compact ? 4 : 6,
            ),
            decoration: BoxDecoration(
              color: context.colors.cardSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.colors.border),
            ),
            child: Column(
              children: [
                Text(
                  chip.label,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  chip.value,
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.bold,
                    color: chip.valueColor,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return Padding(
      padding: EdgeInsets.all(pad),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(iconPad),
                      decoration: BoxDecoration(
                        color: iconBg.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconBg, size: iconSize),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: titleBlock),
                  ],
                ),
                if (chips != null && chips!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  chipRow(chips!),
                ],
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(iconPad),
                  decoration: BoxDecoration(
                    color: iconBg.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconBg, size: iconSize),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: titleBlock),
                if (chips != null) ...[
                  const SizedBox(width: AppSpacing.md),
                  chipRow(chips!),
                ],
              ],
            ),
    );
  }
}
