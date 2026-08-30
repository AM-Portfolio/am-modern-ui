import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';

class FpStatusPill extends StatelessWidget {
  final String label;
  final String? subLabel;
  final Color color;

  const FpStatusPill({
    super.key,
    required this.label,
    this.subLabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              Icon(Icons.circle, size: 8, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (subLabel != null) ...[
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
