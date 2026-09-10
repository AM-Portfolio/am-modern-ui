import 'dart:math' as math;

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/portfolio_intelligence.dart';
import '../../../providers/portfolio_intelligence_providers.dart';
import 'intelligence_glass_card.dart';

class PortfolioHealthCard extends ConsumerWidget {
  const PortfolioHealthCard({
    required this.portfolioId,
    this.compact = false,
    this.maxComponents,
    super.key,
  });

  final String portfolioId;
  final bool compact;

  /// Phone shows top N; null = all (up to 8).
  final int? maxComponents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(portfolioIntelligenceProvider(portfolioId));

    return async.when(
      loading: () => const IntelligenceCardSkeleton(height: 280),
      error: (e, _) => IntelligenceGlassCard(
        title: 'Health Score',
        icon: Icons.favorite_rounded,
        child: IntelligenceRetryRow(
          message: 'Could not load health score',
          onRetry: () =>
              ref.invalidate(portfolioIntelligenceProvider(portfolioId)),
        ),
      ),
      data: (intel) {
        final health = intel?.health;
        if (health == null) {
          return IntelligenceGlassCard(
            title: 'Health Score',
            icon: Icons.favorite_rounded,
            child: Text(
              'Health data unavailable',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }

        final limit = maxComponents ?? (compact ? 4 : 8);
        final shown = health.components.take(limit).toList();

        return IntelligenceGlassCard(
          title: 'Health Score',
          icon: Icons.favorite_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _HealthGauge(score: health.score, band: health.band),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          health.score.toStringAsFixed(0),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ModuleColors.portfolio,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _bandColor(health.band).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            health.band,
                            style: TextStyle(
                              color: _bandColor(health.band),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...shown.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ComponentRow(component: c),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => showIntelligenceSheet(
                    context: context,
                    title: 'Health Details',
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Score ${health.score.toStringAsFixed(0)} · ${health.band}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ...health.components.map(
                          (c) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ComponentRow(component: c, detailed: true),
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('View Details'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _bandColor(String band) {
    switch (band.toLowerCase()) {
      case 'strong':
        return const Color(0xFF00B894);
      case 'healthy':
        return const Color(0xFF55EFC4);
      case 'critical':
        return const Color(0xFFFF7675);
      case 'watch':
      default:
        return const Color(0xFFFDCB6E);
    }
  }
}

class _ComponentRow extends StatelessWidget {
  const _ComponentRow({required this.component, this.detailed = false});

  final HealthComponent component;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final score = component.score.clamp(0, 100) / 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                component.displayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              component.score.toStringAsFixed(0),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score,
            minHeight: 6,
            backgroundColor: ModuleColors.portfolio.withValues(alpha: 0.12),
            color: ModuleColors.portfolio,
          ),
        ),
        if (detailed && (component.reason?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 4),
          Text(
            component.reason!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
        ],
      ],
    );
  }
}

class _HealthGauge extends StatelessWidget {
  const _HealthGauge({required this.score, required this.band});

  final double score;
  final String band;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _GaugePainter(
          progress: (score.clamp(0, 100)) / 100,
          color: ModuleColors.portfolio,
        ),
        child: Center(
          child: Icon(
            Icons.monitor_heart_outlined,
            color: ModuleColors.portfolio,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final bg = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -math.pi / 2,
      2 * math.pi,
      false,
      bg,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
