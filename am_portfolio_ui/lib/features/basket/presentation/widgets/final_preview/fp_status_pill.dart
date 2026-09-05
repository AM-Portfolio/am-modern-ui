import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class FpStatusPill extends StatelessWidget {
  final String label;
  final String? subLabel;
  final Color color;
  final bool compact;

  const FpStatusPill({
    super.key,
    required this.label,
    this.subLabel,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final showSub = !compact && subLabel != null;
    final pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: compact ? 6 : 8, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (showSub) ...[
            const SizedBox(height: 2),
            Text(
              subLabel!,
              style: TextStyle(
                color: context.colors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );

    if (subLabel != null) {
      return Tooltip(
        message: subLabel,
        child: pill,
      );
    }
    return pill;
  }
}
