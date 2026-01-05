import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HeatmapSkeletonLoader extends StatelessWidget {
  const HeatmapSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Controls Skeleton
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 120,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1200.ms, color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)),
              const SizedBox(width: 16),
              Container(
                width: 100,
                height: 32,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 1200.ms, delay: 200.ms, color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)),
            ],
          ),
        ),
        
        // Heatmap Grid Skeleton
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Create a grid of random sized boxes to simulate treemap/heatmap
                return Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: List.generate(12, (index) {
                    final width = (constraints.maxWidth / 4) - 6;
                    final height = index % 3 == 0 ? 160.0 : 80.0;
                    
                    return Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.1)),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 60,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ).animate(onPlay: (controller) => controller.repeat())
                     .shimmer(duration: 1200.ms, delay: (100 * index).ms, color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5));
                  }),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
