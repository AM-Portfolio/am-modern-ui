import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../internal/domain/entities/portfolio_intelligence.dart';

/// Paint-only floor so a true 0 score does not collapse a vertex to the origin.
const double kRiskRadarVisualFloor = 0.08;

/// Sweep period (seconds per full revolution).
const double kRiskRadarSweepSeconds = 7;

/// Half-width of the sweep wedge in radians (~18°).
const double kRiskRadarSweepHalfWidth = 0.32;

/// Gold used for polygon glow, pedestal, and factor-card focus border.
const Color kRiskRadarPolygonGold = Color(0xFFF5C542);

/// Primary shout-radar paint order (top → right → bottom → left).
/// Vol/Beta omitted this pass so the 4-spoke chart stays readable.
const List<String> kRiskRadarPrimaryAxisIds = [
  'CONCENTRATION',
  'SECTOR',
  'DIVERSIFICATION',
  'LIQUIDITY',
];

const Color _kConcentrationAccent = Color(0xFFE91E8C);
const Color _kSectorAccent = Color(0xFF00D4FF);
const Color _kDiversificationAccent = Color(0xFF3DDC97);
const Color _kLiquidityAccent = Color(0xFFF5C542);

double riskRadarAxisAngle(int index, int n, {double yaw = 0}) {
  return -math.pi / 2 + (2 * math.pi * index / n) + yaw;
}

double riskRadarVisualT(double riskScore) {
  final raw = riskScore.clamp(0, 100) / 100;
  return math.max(raw, kRiskRadarVisualFloor);
}

String riskRadarAxisLabel(RiskAxis axis) {
  switch (axis.id.toUpperCase()) {
    case 'CONCENTRATION':
      return 'Concentration risk';
    case 'SECTOR':
      return 'Sector risk';
    case 'DIVERSIFICATION':
      return 'Diversification risk';
    case 'LIQUIDITY':
      return 'Liquidity risk';
    default:
      return axis.displayName;
  }
}

/// Explicit chart name lines — never mid-word wrap on the radar canvas.
({String line1, String line2}) riskRadarChartNameLines(RiskAxis axis) {
  switch (axis.id.toUpperCase()) {
    case 'CONCENTRATION':
      return (line1: 'Concentration', line2: 'risk');
    case 'SECTOR':
      return (line1: 'Sector', line2: 'risk');
    case 'DIVERSIFICATION':
      return (line1: 'Diversification', line2: 'risk');
    case 'LIQUIDITY':
      return (line1: 'Liquidity', line2: 'risk');
    default:
      final parts = riskRadarAxisLabel(axis).split(' ');
      if (parts.length >= 2 && parts.last.toLowerCase() == 'risk') {
        return (
          line1: parts.sublist(0, parts.length - 1).join(' '),
          line2: 'risk',
        );
      }
      return (line1: riskRadarAxisLabel(axis), line2: '');
  }
}

/// Risk score display on chart + list (0–100 scale, not a %).
String riskRadarScoreLabel(num score) => '${score.round()} / 100';

/// Compact chart tip score; full `n / 100` stays on the right-hand list.
String riskRadarChartScoreLabel(num score) => '(${score.round()})';

String riskRadarBandLabel(double riskScore) {
  if (riskScore >= 70) return 'High';
  if (riskScore >= 40) return 'Medium';
  return 'Good';
}

String riskRadarBandSeverity(double riskScore) {
  if (riskScore >= 70) return 'HIGH';
  if (riskScore >= 40) return 'MEDIUM';
  return 'GOOD';
}

/// Accent color for chart spokes/vertices and matching factor cards.
Color riskRadarAxisAccent(String axisId) {
  switch (axisId.toUpperCase()) {
    case 'CONCENTRATION':
      return _kConcentrationAccent;
    case 'SECTOR':
      return _kSectorAccent;
    case 'DIVERSIFICATION':
      return _kDiversificationAccent;
    case 'LIQUIDITY':
      return _kLiquidityAccent;
    default:
      return kRiskRadarPolygonGold;
  }
}

IconData riskRadarAxisIcon(String axisId) {
  switch (axisId.toUpperCase()) {
    case 'CONCENTRATION':
      return Icons.filter_center_focus_rounded;
    case 'SECTOR':
      return Icons.donut_large_rounded;
    case 'DIVERSIFICATION':
      return Icons.hub_rounded;
    case 'LIQUIDITY':
      return Icons.water_drop_rounded;
    default:
      return Icons.radar_rounded;
  }
}

/// Ordered primary axes present in [axes] (Vol/Beta excluded from shout UI).
List<RiskAxis> riskRadarPrimaryAxes(List<RiskAxis> axes) {
  final byId = <String, RiskAxis>{
    for (final a in axes) a.id.toUpperCase(): a,
  };
  return [
    for (final id in kRiskRadarPrimaryAxisIds)
      if (byId.containsKey(id)) byId[id]!,
  ];
}

/// Finding code → axis id for expand-body enrichment only.
String? riskRadarFindingAxisId(String code) {
  switch (code.toUpperCase()) {
    case 'TOP1_HIGH':
      return 'CONCENTRATION';
    case 'SECTOR_HIGH':
    case 'SECTOR_MEDIUM':
      return 'SECTOR';
    case 'BETA_HIGH':
    case 'BETA_MEDIUM':
      return 'BETA';
    default:
      return null;
  }
}

RiskFinding? riskRadarFindingForAxis(
  List<RiskFinding> findings,
  String axisId,
) {
  final want = axisId.toUpperCase();
  for (final f in findings) {
    final mapped = riskRadarFindingAxisId(f.code);
    if (mapped != null && mapped.toUpperCase() == want) return f;
  }
  return null;
}

/// Flat radar point (y up in math space → screen y down).
Offset riskRadarFlatPoint({
  required Offset center,
  required double radius,
  required double angle,
  required double radiusFraction,
}) {
  final r = radius * radiusFraction;
  return Offset(
    center.dx + r * math.cos(angle),
    center.dy + r * math.sin(angle),
  );
}

/// Normalize angle to [-pi, pi).
double riskRadarNormAngle(double a) {
  var x = a;
  while (x < -math.pi) {
    x += 2 * math.pi;
  }
  while (x >= math.pi) {
    x -= 2 * math.pi;
  }
  return x;
}

/// Smallest absolute delta between two angles.
double riskRadarAngleDelta(double a, double b) {
  return riskRadarNormAngle(a - b).abs();
}

/// Axis index nearest to [sweepAngle], or -1 if outside [halfWidth].
int riskRadarSweepHitAxis({
  required double sweepAngle,
  required int n,
  double halfWidth = kRiskRadarSweepHalfWidth,
}) {
  if (n < 1) return -1;
  var best = -1;
  var bestDelta = halfWidth;
  for (var i = 0; i < n; i++) {
    final axisAngle = riskRadarAxisAngle(i, n);
    final d = riskRadarAngleDelta(sweepAngle, axisAngle);
    if (d <= bestDelta) {
      bestDelta = d;
      best = i;
    }
  }
  return best;
}

int riskRadarHitTestFlat({
  required Offset local,
  required List<RiskAxis> axes,
  required Offset center,
  required double radius,
  double slop = 28,
}) {
  final n = axes.length;
  if (n < 3) return -1;
  var best = -1;
  var bestDist = slop;
  for (var i = 0; i < n; i++) {
    final angle = riskRadarAxisAngle(i, n);
    final t = riskRadarVisualT(axes[i].riskScore);
    final p = riskRadarFlatPoint(
      center: center,
      radius: radius,
      angle: angle,
      radiusFraction: t,
    );
    final tip = riskRadarFlatPoint(
      center: center,
      radius: radius,
      angle: angle,
      radiusFraction: 1,
    );
    final d = math.min((p - local).distance, (tip - local).distance);
    if (d <= bestDist) {
      bestDist = d;
      best = i;
    }
  }
  return best;
}

/// One-paragraph Key Insight for the accordion expand body.
String riskRadarKeyInsightParagraph(String axisId) {
  final edu = riskRadarAxisEducation(axisId);
  return '${edu.meaning} ${edu.tip}';
}

/// User-facing education (plain language — no engine formulas).
({String meaning, String tip}) riskRadarAxisEducation(String axisId) {
  switch (axisId.toUpperCase()) {
    case 'LIQUIDITY':
      return (
        meaning:
            'Liquidity is how easily you can turn holdings into cash without '
            'a big price hit.',
        tip:
            'A higher score means more of your book may be harder to exit '
            'quickly. Lower is usually healthier for flexibility.',
      );
    case 'SECTOR':
      return (
        meaning:
            'Sector risk shows whether too much value sits in one industry '
            '(for example banks or IT).',
        tip:
            'A higher score means one sector dominates. Spreading across '
            'sectors can reduce this concentration.',
      );
    case 'CONCENTRATION':
      return (
        meaning:
            'Concentration is how much of your portfolio rides on a few '
            'large holdings.',
        tip:
            'A higher score means your outcomes depend heavily on a small '
            'set of names. Spreading weight can lower this risk.',
      );
    case 'DIVERSIFICATION':
      return (
        meaning:
            'Diversification reflects how evenly risk is spread across '
            'your holdings.',
        tip:
            'A higher score means the book is less well spread out. '
            'Broader, more balanced holdings usually lower this score.',
      );
    case 'VOLATILITY':
      return (
        meaning:
            'Volatility describes how much your portfolio value tends to '
            'swing up and down.',
        tip:
            'A higher score means larger swings. That can mean more '
            'opportunity and more stress for your returns.',
      );
    case 'BETA':
      return (
        meaning:
            'Beta is how strongly your portfolio tends to move with the '
            'overall market.',
        tip:
            'A higher score means more market sensitivity. Your book may '
            'rise and fall more when the market does.',
      );
    default:
      return (
        meaning: 'This factor is one way we look at portfolio risk.',
        tip:
            'A higher score means more risk on this factor. Tap other '
            'rows to compare.',
      );
  }
}
