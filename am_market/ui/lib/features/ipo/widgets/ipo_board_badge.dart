import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';

class IpoBoardBadge extends StatelessWidget {
  final String? issueType;

  const IpoBoardBadge({super.key, required this.issueType});

  @override
  Widget build(BuildContext context) {
    final type = (issueType ?? '').toLowerCase();
    final isSme = type.contains('sme');
    final label = isSme ? 'SME' : 'Mainboard';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isSme ? IpoColors.smeBadge : IpoColors.mainboardBadge;
    final bgColor = baseColor.withValues(alpha: isDark ? 0.2 : 0.12);
    final textColor = isDark ? baseColor : baseColor;
    final borderColor = baseColor.withValues(alpha: isDark ? 0.4 : 0.3);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
