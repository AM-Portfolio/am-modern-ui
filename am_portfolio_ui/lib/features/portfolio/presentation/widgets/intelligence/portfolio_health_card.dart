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
    this.minHeight,
    this.fillHeight = false,
    super.key,
  });

  final String portfolioId;
  final bool compact;
  final int? maxComponents;
  final double? minHeight;
  final bool fillHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(portfolioIntelligenceProvider(portfolioId));

    return async.when(
      loading: () => IntelligenceCardSkeleton(height: minHeight ?? (fillHeight ? 340 : 220)),
      error: (e, _) => IntelligenceGlassCard(
        title: 'Health Score',
        icon: Icons.favorite_rounded,
        minHeight: minHeight,
        fillHeight: fillHeight,
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
            minHeight: minHeight,
            fillHeight: fillHeight,
            child: Text(
              'Health data unavailable',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }

        final limit = maxComponents ?? (compact ? 4 : 8);
        final shown = health.components.take(limit).toList();
        final focus = [...health.components]
          ..sort((a, b) => a.score.compareTo(b.score));
        final focusNames = focus.take(2).map((c) => c.displayName).join(' · ');

        return IntelligenceGlassCard(
          title: 'Health Score',
          icon: Icons.favorite_rounded,
          minHeight: minHeight,
          fillHeight: fillHeight,
          footer: IntelligenceTextLink(
            label: 'View Details →',
            onPressed: () => showIntelligenceSheet(
              context: context,
              title: 'Health Details',
              subtitle: 'Score ${health.score.toStringAsFixed(0)} / 100 · ${health.band}',
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...health.components.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ComponentTile(component: c, detailed: true),
                    ),
                  ),
                ],
              ),
            ),
          ),
          child: _HealthBody(
            fillHeight: fillHeight,
            score: health.score,
            band: health.band,
            focusNames: focusNames,
            components: shown,
            bandColor: _bandColor(health.band),
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

class _HealthBody extends StatelessWidget {
  const _HealthBody({
    required this.fillHeight,
    required this.score,
    required this.band,
    required this.focusNames,
    required this.components,
    required this.bandColor,
  });

  final bool fillHeight;
  final double score;
  final String band;
  final String focusNames;
  final List<HealthComponent> components;
  final Color bandColor;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _HealthGauge(score: score, band: band),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: score.toStringAsFixed(0),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ModuleColors.portfolio,
                              ),
                        ),
                        TextSpan(
                          text: ' / 100',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).hintColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bandColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      band,
                      style: TextStyle(
                        color: bandColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (focusNames.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Focus: $focusNames',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _ComponentGrid(components: components),
      ],
    );

    // Peer stretch gives a tight body height; scroll instead of overflowing.
    if (fillHeight) {
      return SingleChildScrollView(child: column);
    }
    return column;
  }
}

class _ComponentGrid extends StatelessWidget {
  const _ComponentGrid({required this.components});

  final List<HealthComponent> components;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 280.0;
        final colW = (maxW - 8) / 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: components
              .map(
                (c) => SizedBox(
                  width: colW,
                  child: _ComponentTile(component: c),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ComponentTile extends StatelessWidget {
  const _ComponentTile({required this.component, this.detailed = false});

  final HealthComponent component;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    final severity = (component.severity ?? '').toUpperCase();
    final dot = switch (severity) {
      'HIGH' || 'CRITICAL' => const Color(0xFFFF7675),
      'MEDIUM' || 'WATCH' => const Color(0xFFFDCB6E),
      'GOOD' || 'OK' || 'LOW' => const Color(0xFF00B894),
      _ => ModuleColors.portfolio,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                component.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              component.score.toStringAsFixed(0),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
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
      width: 88,
      height: 88,
      child: CustomPaint(
        painter: _GaugePainter(
          progress: (score.clamp(0, 100)) / 100,
          color: ModuleColors.portfolio,
        ),
        child: Center(
          child: Icon(
            Icons.monitor_heart_outlined,
            color: ModuleColors.portfolio,
            size: 26,
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
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
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
