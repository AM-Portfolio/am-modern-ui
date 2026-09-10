import 'dart:math' as math;

import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../internal/domain/entities/portfolio_intelligence.dart';
import '../../../providers/portfolio_intelligence_providers.dart';
import 'intelligence_glass_card.dart';

class PortfolioRiskRadarCard extends ConsumerWidget {
  const PortfolioRiskRadarCard({
    required this.portfolioId,
    super.key,
  });

  final String portfolioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(portfolioIntelligenceProvider(portfolioId));

    return async.when(
      loading: () => const IntelligenceCardSkeleton(height: 280),
      error: (e, _) => IntelligenceGlassCard(
        title: 'Risk Radar',
        icon: Icons.radar_rounded,
        child: IntelligenceRetryRow(
          message: 'Could not load risk radar',
          onRetry: () =>
              ref.invalidate(portfolioIntelligenceProvider(portfolioId)),
        ),
      ),
      data: (intel) {
        final risk = intel?.risk;
        if (risk == null || risk.axes.isEmpty) {
          return IntelligenceGlassCard(
            title: 'Risk Radar',
            icon: Icons.radar_rounded,
            child: Text(
              'Risk data unavailable',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }

        final findings = risk.findings.take(4).toList();

        return IntelligenceGlassCard(
          title: 'Risk Radar',
          icon: Icons.radar_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: CustomPaint(
                    painter: _RadarPainter(
                      axes: risk.axes,
                      color: ModuleColors.portfolio,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: risk.axes
                    .map(
                      (a) => Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          '${a.displayName} ${a.riskScore.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (findings.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...findings.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: 16,
                          color: _severityColor(f.severity),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            f.label,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => showIntelligenceSheet(
                    context: context,
                    title: 'Risk Analysis',
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...risk.axes.map(
                          (a) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(a.displayName),
                            trailing: Text(a.riskScore.toStringAsFixed(0)),
                          ),
                        ),
                        const Divider(),
                        ...risk.findings.map(
                          (f) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.flag_outlined,
                              color: _severityColor(f.severity),
                            ),
                            title: Text(f.label),
                            subtitle: Text(f.code),
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: const Text('View Risk Analysis'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _severityColor(String? severity) {
    switch ((severity ?? '').toUpperCase()) {
      case 'HIGH':
      case 'CRITICAL':
        return const Color(0xFFFF7675);
      case 'MEDIUM':
      case 'WATCH':
        return const Color(0xFFFDCB6E);
      default:
        return ModuleColors.portfolio;
    }
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.axes, required this.color});

  final List<RiskAxis> axes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final n = axes.length;
    if (n < 3) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    final grid = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * (ring / 4);
      final path = Path();
      for (var i = 0; i < n; i++) {
        final angle = -math.pi / 2 + (2 * math.pi * i / n);
        final p = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.close();
      canvas.drawPath(path, grid);
    }

    final data = Path();
    for (var i = 0; i < n; i++) {
      final score = axes[i].riskScore.clamp(0, 100) / 100;
      final angle = -math.pi / 2 + (2 * math.pi * i / n);
      final r = radius * score;
      final p = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      if (i == 0) {
        data.moveTo(p.dx, p.dy);
      } else {
        data.lineTo(p.dx, p.dy);
      }
    }
    data.close();
    canvas.drawPath(data, fill);
    canvas.drawPath(data, stroke);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.axes != axes || oldDelegate.color != color;
}
