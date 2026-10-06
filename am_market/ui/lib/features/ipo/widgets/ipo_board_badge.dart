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

    final bgColor = isSme
        ? (isDark ? const Color(0xFF0369A1).withValues(alpha: 0.35) : const Color(0xFFE0F2FE))
        : (isDark ? const Color(0xFF581C87).withValues(alpha: 0.35) : const Color(0xFFF3E8FF));

    final textColor = isSme
        ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
        : (isDark ? const Color(0xFFC084FC) : const Color(0xFF7E22CE));

    final borderColor = isSme
        ? (isDark ? const Color(0xFF0284C7).withValues(alpha: 0.5) : const Color(0xFFBAE6FD))
        : (isDark ? const Color(0xFF7E22CE).withValues(alpha: 0.5) : const Color(0xFFE9D5FF));

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
