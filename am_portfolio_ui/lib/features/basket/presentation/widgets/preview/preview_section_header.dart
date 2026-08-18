import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../../../domain/models/basket_enums.dart';

class PreviewSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final ItemStatus statusType;

  const PreviewSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusType,
  });

  Color _getColorForStatus(BuildContext context) {
    switch (statusType) {
      case ItemStatus.held:
        return context.statusSuccess;
      case ItemStatus.substitute:
        return context.statusWarning;
      case ItemStatus.missing:
        return context.statusError;
    }
  }

  IconData _getIconForStatus() {
    switch (statusType) {
      case ItemStatus.held:
        return Icons.check_circle_outline;
      case ItemStatus.substitute:
        return Icons.swap_horiz;
      case ItemStatus.missing:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorForStatus(context);
    final icon = _getIconForStatus();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border(
          left: BorderSide(
            color: color,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color.withOpacity(0.9),
                      ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
