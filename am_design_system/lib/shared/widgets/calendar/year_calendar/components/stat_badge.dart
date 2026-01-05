import 'package:flutter/material.dart';

/// Stat badge component for displaying statistics
class StatBadge extends StatelessWidget {
  const StatBadge({required this.icon, required this.label, required this.color, super.key, this.compact = false});

  final IconData icon;
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isCompact = compact || isMobile;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 5 : 8, vertical: isCompact ? 2 : 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(isCompact ? 4 : 6),
        border: Border.all(color: color.withOpacity(0.3), width: isCompact ? 0.5 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 9 : 12, color: color),
          SizedBox(width: isCompact ? 2 : 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: isCompact ? 9 : 10,
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
