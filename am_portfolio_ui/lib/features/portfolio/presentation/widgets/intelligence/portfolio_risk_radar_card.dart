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
    this.minHeight,
    this.fillHeight = false,
    super.key,
  });

  final String portfolioId;
  final double? minHeight;
  final bool fillHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(portfolioIntelligenceProvider(portfolioId));
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return async.when(
      loading: () =>
          IntelligenceCardSkeleton(height: minHeight ?? (fillHeight ? 320 : 220)),
      error: (e, _) => IntelligenceGlassCard(
        title: 'Risk Radar',
        icon: Icons.radar_rounded,
        minHeight: minHeight,
        fillHeight: fillHeight,
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
            minHeight: minHeight,
            fillHeight: fillHeight,
            child: const IntelligenceEmptyHint(message: 'Risk data unavailable'),
          );
        }

        final rows = _displayFindings(risk);
        final spiderSize = isPhone ? 170.0 : (fillHeight ? 210.0 : 190.0);

        void openSheet() => showIntelligenceSheet(
              context: context,
              title: 'Risk Analysis',
              subtitle: 'Axes and threshold findings',
              body: _RiskAnalysisBody(risk: risk, rows: rows),
            );

        final spider = SizedBox(
          width: spiderSize,
          height: spiderSize,
          child: CustomPaint(
            painter: _RadarPainter(
              axes: risk.axes,
              color: ModuleColors.portfolio,
              labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w600,
                    fontSize: isPhone ? 9.5 : 10.5,
                  ),
            ),
          ),
        );

        final sideCol = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...rows.map((r) => _FindingDisplayRow(row: r)),
          ],
        );

        final content = isPhone
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(child: spider),
                  const SizedBox(height: 12),
                  sideCol,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 5,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: spider,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(flex: 6, child: sideCol),
                ],
              );

        return IntelligenceGlassCard(
          title: 'Risk Radar',
          icon: Icons.radar_rounded,
          minHeight: minHeight,
          fillHeight: fillHeight,
          footer: _OutlinedRiskCta(
            label: 'View Risk Analysis →',
            onPressed: openSheet,
          ),
          child: fillHeight
              ? SingleChildScrollView(child: content)
              : content,
        );
      },
    );
  }
}

class _OutlinedRiskCta extends StatelessWidget {
  const _OutlinedRiskCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: ModuleColors.portfolio,
          side: BorderSide(
            color: ModuleColors.portfolio.withValues(alpha: 0.65),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _DisplayFinding {
  const _DisplayFinding({
    required this.label,
    required this.value,
    required this.severity,
  });

  final String label;
  final String value;
  final String severity;
}

/// Findings-first; empty → axes sorted by riskScore desc with score-band severity.
List<_DisplayFinding> _displayFindings(PortfolioRisk risk) {
  if (risk.findings.isNotEmpty) {
    return risk.findings.take(4).map((f) {
      final sev = (f.severity ?? 'GOOD').toUpperCase();
      final valueMatch = RegExp(r'([\d.]+%?)\s*$').firstMatch(f.label.trim());
      final value = valueMatch?.group(1) ?? '—';
      var label = f.label.trim();
      if (valueMatch != null) {
        label = label.substring(0, valueMatch.start).trim();
      }
      if (label.isEmpty) label = f.code;
      return _DisplayFinding(label: label, value: value, severity: sev);
    }).toList();
  }

  final sorted = [...risk.axes]
    ..sort((a, b) => b.riskScore.compareTo(a.riskScore));
  return sorted.take(4).map((a) {
    return _DisplayFinding(
      label: _axisLabel(a),
      value: a.riskScore.toStringAsFixed(0),
      severity: _bandSeverity(a.riskScore),
    );
  }).toList();
}

String _axisLabel(RiskAxis a) {
  if (a.id.toUpperCase() == 'SECTOR') return 'Sector Risk';
  return a.displayName;
}

/// High ≥70 / Medium ≥40 / Good &lt;40 — axis fallback only.
String _bandSeverity(double riskScore) {
  if (riskScore >= 70) return 'HIGH';
  if (riskScore >= 40) return 'MEDIUM';
  return 'GOOD';
}

class _FindingDisplayRow extends StatelessWidget {
  const _FindingDisplayRow({required this.row});

  final _DisplayFinding row;

  @override
  Widget build(BuildContext context) {
    final pill = switch (row.severity.toUpperCase()) {
      'HIGH' || 'CRITICAL' => 'High',
      'MEDIUM' || 'WATCH' => 'Medium',
      _ => 'Good',
    };
    final color = _severityColor(row.severity);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              row.label,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            row.value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Text(
              pill,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskAnalysisBody extends StatelessWidget {
  const _RiskAnalysisBody({required this.risk, required this.rows});

  final PortfolioRisk risk;
  final List<_DisplayFinding> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          risk.findings.isNotEmpty ? 'Findings' : 'Risk signals',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        if (rows.isEmpty)
          const IntelligenceEmptyHint(message: 'No findings to show')
        else
          ...rows.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FindingDisplayRow(row: r),
            ),
          ),
        const SizedBox(height: 16),
        Text(
          'Axis scores',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 10),
        ...risk.axes.map((a) {
          final v = (a.riskScore / 100).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(_axisLabel(a))),
                    Text(
                      a.riskScore.toStringAsFixed(0),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 5,
                    backgroundColor:
                        ModuleColors.portfolio.withValues(alpha: 0.12),
                    color: ModuleColors.portfolio,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
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
      return const Color(0xFF00B894);
  }
}

/// Labeled N-gon radar: spokes, rings, visual floor, vertex dots, web-safe glow.
class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.axes,
    required this.color,
    this.labelStyle,
  });

  final List<RiskAxis> axes;
  final Color color;
  final TextStyle? labelStyle;

  static const double _labelGutter = 28;
  static const double _visualFloor = 0.08;

  @override
  void paint(Canvas canvas, Size size) {
    final n = axes.length;
    if (n < 3) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius =
        math.min(size.width, size.height) / 2 - _labelGutter;

    final grid = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final spoke = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    final glow = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;
    final vertexFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var ring = 1; ring <= 4; ring++) {
      final r = radius * (ring / 4);
      canvas.drawPath(_polygonPath(center, r, n), grid);
    }

    for (var i = 0; i < n; i++) {
      final angle = _angle(i, n);
      final tip = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, tip, spoke);
    }

    final dataPts = <Offset>[];
    final data = Path();
    for (var i = 0; i < n; i++) {
      final raw = axes[i].riskScore.clamp(0, 100) / 100;
      final t = math.max(raw, _visualFloor);
      final angle = _angle(i, n);
      final r = radius * t;
      final p = Offset(
        center.dx + r * math.cos(angle),
        center.dy + r * math.sin(angle),
      );
      dataPts.add(p);
      if (i == 0) {
        data.moveTo(p.dx, p.dy);
      } else {
        data.lineTo(p.dx, p.dy);
      }
    }
    data.close();
    canvas.drawPath(data, fill);
    canvas.drawPath(data, glow);
    canvas.drawPath(data, stroke);

    for (final p in dataPts) {
      canvas.drawCircle(p, 3.2, vertexFill);
    }

    final style = labelStyle ??
        TextStyle(
          color: color.withValues(alpha: 0.75),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        );
    for (var i = 0; i < n; i++) {
      final angle = _angle(i, n);
      final label = _axisLabel(axes[i]);
      final tp = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 72);

      final labelR = radius + 10;
      var dx = center.dx + labelR * math.cos(angle) - tp.width / 2;
      var dy = center.dy + labelR * math.sin(angle) - tp.height / 2;
      dx = dx.clamp(0.0, size.width - tp.width);
      dy = dy.clamp(0.0, size.height - tp.height);
      tp.paint(canvas, Offset(dx, dy));
    }
  }

  static double _angle(int i, int n) =>
      -math.pi / 2 + (2 * math.pi * i / n);

  static Path _polygonPath(Offset center, double r, int n) {
    final path = Path();
    for (var i = 0; i < n; i++) {
      final angle = _angle(i, n);
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
    return path;
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    if (oldDelegate.color != color ||
        oldDelegate.labelStyle != labelStyle ||
        oldDelegate.axes.length != axes.length) {
      return true;
    }
    for (var i = 0; i < axes.length; i++) {
      if (oldDelegate.axes[i].id != axes[i].id ||
          oldDelegate.axes[i].riskScore != axes[i].riskScore) {
        return true;
      }
    }
    return false;
  }
}
