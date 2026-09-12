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
      'Sector risk',
    );
    expect(
      riskRadarAxisLabel(const RiskAxis(id: 'CONCENTRATION', riskScore: 10)),
      'Concentration risk',
    );
    final edu = riskRadarAxisEducation('LIQUIDITY');
    expect(edu.meaning.toLowerCase(), contains('cash'));
    expect(edu.tip.toLowerCase(), contains('higher'));
    expect(edu.meaning.toLowerCase(), isNot(contains('100 −')));
  });

  test('chart name lines never mid-word wrap long axes', () {
    final conc = riskRadarChartNameLines(
      const RiskAxis(id: 'CONCENTRATION', riskScore: 10),
    );
    expect(conc.line1, 'Concentration');
    expect(conc.line2, 'risk');
    final div = riskRadarChartNameLines(
      const RiskAxis(id: 'DIVERSIFICATION', riskScore: 0),
    );
    expect(div.line1, 'Diversification');
    expect(div.line2, 'risk');
    final sector = riskRadarChartNameLines(
      const RiskAxis(id: 'SECTOR', riskScore: 29),
    );
    expect(sector.line1, 'Sector');
    expect(sector.line2, 'risk');
    final liq = riskRadarChartNameLines(
      const RiskAxis(id: 'LIQUIDITY', riskScore: 45),
    );
    expect(liq.line1, 'Liquidity');
    expect(liq.line2, 'risk');
  });

  test('score label is n / 100 not a percent', () {
    expect(riskRadarScoreLabel(10), '10 / 100');
    expect(riskRadarScoreLabel(45.4), '45 / 100');
    expect(riskRadarScoreLabel(0), '0 / 100');
  });

  test('chart score label is compact paren', () {
    expect(riskRadarChartScoreLabel(29), '(29)');
    expect(riskRadarChartScoreLabel(10), '(10)');
    expect(riskRadarChartScoreLabel(45.4), '(45)');
    expect(riskRadarChartScoreLabel(0), '(0)');
  });

  test('band labels match display thresholds', () {
    expect(riskRadarBandLabel(72), 'High');
    expect(riskRadarBandLabel(45), 'Medium');
    expect(riskRadarBandLabel(10), 'Good');
  });

  test('primary axes keep shout paint order and omit vol/beta', () {
    final primary = riskRadarPrimaryAxes(const [
      RiskAxis(id: 'beta', riskScore: 60),
      RiskAxis(id: 'liquidity', riskScore: 20),
      RiskAxis(id: 'volatility', riskScore: 80),
      RiskAxis(id: 'sector', riskScore: 40),
      RiskAxis(id: 'concentration', riskScore: 10),
      RiskAxis(id: 'diversification', riskScore: 5),
    ]);
    expect(primary.map((a) => a.id.toUpperCase()).toList(), [
      'CONCENTRATION',
      'SECTOR',
      'DIVERSIFICATION',
      'LIQUIDITY',
    ]);
  });

  test('finding code maps to axis and resolves finding', () {
    expect(riskRadarFindingAxisId('TOP1_HIGH'), 'CONCENTRATION');
    expect(riskRadarFindingAxisId('SECTOR_MEDIUM'), 'SECTOR');
    expect(riskRadarFindingAxisId('BETA_HIGH'), 'BETA');
    expect(riskRadarFindingAxisId('UNKNOWN'), isNull);

    const findings = [
      RiskFinding(
        code: 'SECTOR_HIGH',
        label: 'Banking 31.4%',
        severity: 'HIGH',
      ),
    ];
    final hit = riskRadarFindingForAxis(findings, 'sector');
    expect(hit?.label, 'Banking 31.4%');
    expect(riskRadarFindingForAxis(findings, 'liquidity'), isNull);
  });

  test('axis accent and key insight paragraph', () {
    expect(riskRadarAxisAccent('CONCENTRATION').toARGB32(), 0xFFE91E8C);
    expect(riskRadarAxisAccent('SECTOR').toARGB32(), 0xFF00D4FF);
    final paragraph = riskRadarKeyInsightParagraph('LIQUIDITY');
    expect(paragraph.toLowerCase(), contains('cash'));
    expect(paragraph.toLowerCase(), contains('higher'));
  });
}
