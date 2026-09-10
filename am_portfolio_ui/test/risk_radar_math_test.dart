import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_intelligence.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/risk_radar_math.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('visual floor keeps zero score off the origin', () {
    expect(riskRadarVisualT(0), kRiskRadarVisualFloor);
    expect(riskRadarVisualT(50), 0.5);
    expect(riskRadarVisualT(100), 1.0);
  });

  test('flat point places top axis above center', () {
    const center = Offset(100, 100);
    final top = riskRadarFlatPoint(
      center: center,
      radius: 40,
      angle: riskRadarAxisAngle(0, 4),
      radiusFraction: 1,
    );
    expect(top.dy, lessThan(center.dy));
  });

  test('sweep hit finds nearest axis', () {
    expect(
      riskRadarSweepHitAxis(sweepAngle: riskRadarAxisAngle(0, 4), n: 4),
      0,
    );
    expect(
      riskRadarSweepHitAxis(sweepAngle: riskRadarAxisAngle(2, 4), n: 4),
      2,
    );
  });

  test('hit test finds nearest flat vertex', () {
    final axes = [
      const RiskAxis(id: 'a', riskScore: 40),
      const RiskAxis(id: 'b', riskScore: 40),
      const RiskAxis(id: 'c', riskScore: 40),
      const RiskAxis(id: 'd', riskScore: 40),
    ];
    const center = Offset(100, 100);
    const radius = 60.0;
    final tip0 = riskRadarFlatPoint(
      center: center,
      radius: radius,
      angle: riskRadarAxisAngle(0, 4),
      radiusFraction: 1,
    );
    final hit = riskRadarHitTestFlat(
      local: tip0,
      axes: axes,
      center: center,
      radius: radius,
    );
    expect(hit, 0);
  });

  test('sector label and education copy', () {
    expect(
      riskRadarAxisLabel(const RiskAxis(id: 'SECTOR', riskScore: 10)),
      'Sector Risk',
    );
    final edu = riskRadarAxisEducation('LIQUIDITY');
    expect(edu.meaning.toLowerCase(), contains('cash'));
    expect(edu.tip.toLowerCase(), contains('higher'));
    expect(edu.meaning.toLowerCase(), isNot(contains('100 −')));
  });

  test('band labels match display thresholds', () {
    expect(riskRadarBandLabel(72), 'High');
    expect(riskRadarBandLabel(45), 'Medium');
    expect(riskRadarBandLabel(10), 'Good');
  });
}
