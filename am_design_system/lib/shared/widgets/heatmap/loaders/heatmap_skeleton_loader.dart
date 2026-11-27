import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Animated treemap placeholder shown while heatmap mosaic loads.
class HeatmapSkeletonLoader extends StatelessWidget {
  const HeatmapSkeletonLoader({super.key});

  static const Color _accent = Color(0xFFE91E8C);
  static const Color _gain = Color(0xFF2E7D4F);
  static const Color _loss = Color(0xFFB33A3A);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
                  child: _KpiChip(base: base, accent: _accent, delayMs: i * 80),
                ),
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.grid_view_rounded, size: 18, color: _accent.withOpacity(0.85)),
              const SizedBox(width: 8),
              Text(
                'Building heatmap…',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onSurface.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _accent.withOpacity(0.9),
                ),
              ),
            ],
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.55, end: 1, duration: 900.ms),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                final cells = <_MosaicSpec>[
                  _MosaicSpec(0, 0, 0.38, 0.55, _gain),
                  _MosaicSpec(0.38, 0, 0.34, 0.32, _loss),
                  _MosaicSpec(0.72, 0, 0.28, 0.32, _gain),
                  _MosaicSpec(0.38, 0.32, 0.28, 0.23, _gain),
                  _MosaicSpec(0.66, 0.32, 0.34, 0.23, _loss),
                  _MosaicSpec(0, 0.55, 0.22, 0.45, _loss),
                  _MosaicSpec(0.22, 0.55, 0.30, 0.25, _gain),
                  _MosaicSpec(0.52, 0.55, 0.48, 0.25, _gain),
                  _MosaicSpec(0.22, 0.80, 0.25, 0.20, _loss),
                  _MosaicSpec(0.47, 0.80, 0.53, 0.20, _gain),
                ];

                return Stack(
                  children: [
                    for (var i = 0; i < cells.length; i++)
                      Positioned(
                        left: cells[i].x * w,
                        top: cells[i].y * h,
                        width: cells[i].w * w - 3,
                        height: cells[i].h * h - 3,
                        child: _MosaicTile(
                          color: cells[i].tint,
                          base: base,
                          delayMs: i * 70,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MosaicSpec {
  const _MosaicSpec(this.x, this.y, this.w, this.h, this.tint);
  final double x;
  final double y;
  final double w;
  final double h;
  final Color tint;
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({
    required this.base,
    required this.accent,
    required this.delayMs,
  });

  final Color base;
  final Color accent;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: base.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 8,
            decoration: BoxDecoration(
              color: base.withOpacity(0.55),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const Spacer(),
          Container(
            width: 72,
            height: 12,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.35),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1400.ms,
          delay: delayMs.ms,
          color: accent.withOpacity(0.35),
        );
  }
}

class _MosaicTile extends StatelessWidget {
  const _MosaicTile({
    required this.color,
    required this.base,
    required this.delayMs,
  });

  final Color color;
  final Color base;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.45),
            color.withOpacity(0.18),
            base.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.35),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const Spacer(),
          Container(
            width: 52,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.28),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.45, end: 1, duration: 1100.ms, delay: delayMs.ms)
        .shimmer(
          duration: 1600.ms,
          delay: delayMs.ms,
          color: Colors.white.withOpacity(0.22),
        );
  }
}
