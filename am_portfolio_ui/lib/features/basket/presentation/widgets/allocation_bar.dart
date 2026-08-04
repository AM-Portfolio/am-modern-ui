import 'package:flutter/material.dart';

class AllocationBar extends StatelessWidget {
  final List<AllocationSegment> segments;
  final double height;
  final double borderRadius;

  const AllocationBar({
    super.key,
    required this.segments,
    this.height = 12,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // The Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(
            height: height,
            child: Row(
              children: segments.map((segment) {
                return Expanded(
                  flex: (segment.percentage * 100).round(),
                  child: Container(color: segment.color),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // The Legend
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: segments.map((segment) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: segment.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  segment.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontSize: 11,
                  ),
                ),
                Text(
                  ' ${(segment.percentage * 100).toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class AllocationSegment {
  final String label;
  final double percentage;
  final Color color;

  const AllocationSegment({
    required this.label,
    required this.percentage,
    required this.color,
  });
}
