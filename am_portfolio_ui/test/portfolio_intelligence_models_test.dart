import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_intelligence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PortfolioIntelligence.fromJson parses health risk xray', () {
    final intel = PortfolioIntelligence.fromJson({
      'portfolioId': 'p1',
      'asOf': '2026-09-08T12:00:00Z',
      'confidence': 0.8,
      'health': {
        'score': 72,
        'band': 'Healthy',
        'components': [
          {
            'id': 'DIVERSIFICATION',
            'score': 80,
            'severity': 'OK',
            'reason': 'ok',
          },
        ],
      },
      'risk': {
        'axes': [
          {'id': 'CONCENTRATION', 'riskScore': 40},
        ],
        'findings': [
          {'code': 'SECTOR_HIGH', 'label': 'Banking 31%', 'severity': 'HIGH'},
        ],
      },
      'xray': {
        'totalValue': 1000000,
        'sectorWeights': [
          {'name': 'Financial Services', 'weightPct': 31.4, 'value': 314000},
        ],
        'industryWeights': [],
        'marketCapWeights': [],
      },
    });

    expect(intel.portfolioId, 'p1');
    expect(intel.health?.score, 72);
    expect(intel.health?.band, 'Healthy');
    expect(intel.health?.components.first.displayName, 'Diversification');
    expect(intel.risk?.axes.first.riskScore, 40);
    expect(intel.xray?.sectorWeights.first.weightPct, 31.4);
    expect(intel.xray?.sectorWeights.first.valueInr, 314000);
    expect(intel.xray?.totalValueInr, 1000000);
  });

  test('StressResult and WhatIfResult parse impacts', () {
    final stress = StressResult.fromJson({
      'portfolioId': 'p1',
      'estimateLabel': 'Scenario estimate',
      'scenarios': [
        {'id': 'NIFTY_DOWN_10', 'pctImpact': -8.4, 'absImpact': -77800},
      ],
    });
    expect(stress.scenarios.first.pctImpact, -8.4);

    final whatIf = WhatIfResult.fromJson({
      'mode': 'ADD_INVESTMENT',
      'before': {
        'healthScore': 70,
        'weights': {'RELIANCE': 8.2},
        'sectorWeights': {'Energy': 15.0},
      },
      'after': {
        'healthScore': 72,
        'weights': {'RELIANCE': 13.6},
        'sectorWeights': {'Energy': 20.1},
      },
    });
    expect(whatIf.after?.healthScore, 72);
    expect(whatIf.after?.sectorWeights['Energy'], 20.1);
  });
}
