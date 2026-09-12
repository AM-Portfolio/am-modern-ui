import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_analytics.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_holding.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_intelligence.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/intelligence_donut.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/intelligence_glass_card.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/intelligence_sector_label.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/portfolio_health_card.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/portfolio_risk_radar_card.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/portfolio_stress_card.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/portfolio_what_if_card.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/portfolio_xray_panel.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/movers_widget.dart';
import 'package:am_portfolio_ui/features/portfolio/providers/portfolio_intelligence_providers.dart';
import 'package:am_portfolio_ui/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

PortfolioHolding _holding({
  required String symbol,
  required String sector,
  required double weight,
  double value = 100000,
}) {
  return PortfolioHolding(
    id: symbol,
    symbol: symbol,
    name: symbol,
    companyName: symbol,
    sector: sector,
    industry: 'Banks',
    quantity: 1,
    avgPrice: 1,
    currentPrice: 1,
    investedAmount: value,
    currentValue: value,
    todayChange: 0,
    todayChangePercentage: 0,
    totalGainLoss: 0,
    totalGainLossPercentage: 0,
    portfolioWeight: weight,
  );
}

void main() {
  test('stress presets cover five scenarios', () {
    expect(kStressPresets.length, 5);
    expect(kStressPresets.containsKey('NIFTY_DOWN_10'), isTrue);
    expect(kStressPresets.containsKey('CRASH_2008'), isTrue);
  });

  test('stress batch response maps scenarios by id', () {
    final result = StressResult.fromJson({
      'portfolioId': 'p1',
      'estimateLabel': 'Scenario estimate',
      'scenarios': [
        {'id': 'NIFTY_DOWN_10', 'pctImpact': -3.2, 'absImpact': -12000},
        {'id': 'CRASH_2008', 'pctImpact': -18.0, 'absImpact': -90000},
      ],
    });
    expect(result.estimateLabel, 'Scenario estimate');
    expect(result.scenarios.length, 2);
    final byId = {for (final s in result.scenarios) s.id: s};
    expect(byId['NIFTY_DOWN_10']!.pctImpact, -3.2);
    expect(byId['CRASH_2008']!.absImpact, -90000);
    for (final key in kStressPresets.keys) {
      if (key != 'NIFTY_DOWN_10' && key != 'CRASH_2008') {
        expect(byId.containsKey(key), isFalse);
      }
    }
  });

  test('intelligence donut palette has stable colors', () {
    expect(IntelligenceDonut.palette.length, greaterThanOrEqualTo(6));
    expect(intelligenceDonutColor(0), IntelligenceDonut.palette.first);
    expect(intelligenceDonutColor(8), IntelligenceDonut.palette.first);
  });

  testWidgets('Movers compact shows counts and See Top 10 when data exists',
      (tester) async {
    final movers = Movers(
      topGainers: [
        for (var i = 0; i < 4; i++)
          Stock(
            symbol: 'G$i',
            companyName: 'Gainer $i',
            lastPrice: 100,
            changeAmount: 1,
            changePercent: 1,
            sector: 'IT',
          ),
      ],
      topLosers: [
        Stock(
          symbol: 'L0',
          companyName: 'Loser 0',
          lastPrice: 90,
          changeAmount: -1,
          changePercent: -1,
          sector: 'Energy',
        ),
      ],
    );

    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MoversWidget(
              movers: movers,
              compact: true,
              onViewAll: (_) => opened = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gainers (4)'), findsOneWidget);
    expect(find.text('Losers (1)'), findsOneWidget);
    expect(find.text('See Top 10'), findsOneWidget);
    expect(find.textContaining('Only 4 holdings moved today'), findsOneWidget);

    await tester.tap(find.text('See Top 10'));
    await tester.pump();
    expect(opened, isTrue);
  });

  testWidgets('X-Ray shows Sector/Industry/Cap only — no Asset Class or Tap tabs',
      (tester) async {
    final intel = PortfolioIntelligence(
      portfolioId: 'p1',
      health: null,
      risk: null,
      xray: PortfolioXray(
        sectorWeights: const [
          XrayWeight(name: 'Financial Services', weightPct: 31.4),
          XrayWeight(name: 'IT', weightPct: 18.2),
        ],
        industryWeights: const [
          XrayWeight(name: 'Banks', weightPct: 20.0),
        ],
        marketCapWeights: const [
          XrayWeight(name: 'Large Cap', weightPct: 60.0),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioIntelligenceProvider('p1').overrideWith(
            (ref) async => intel,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 520,
              child: PortfolioXrayPanel(portfolioId: 'p1', minHeight: 480),
            ),
          ),
        ),
      ),
    );
    await tester.pump(); // async provider
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Portfolio X-Ray'), findsOneWidget);
    expect(find.text('Financial Services'), findsWidgets);
    expect(find.text('31.4%'), findsWidgets);
    expect(find.text('Explore Full X-Ray →'), findsNothing);
    expect(find.text('Asset Class'), findsNothing);
    expect(find.text('Tap tabs'), findsNothing);
    expect(find.text('Total Exposure'), findsOneWidget);
    expect(find.text('True Exposure'), findsNothing);
    expect(find.text('100%'), findsWidgets);

    await tester.tap(find.text('Industry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Banks'), findsWidgets);
  });

  test('xrayDisplayName maps Cap keys and Unknown', () {
    expect(xrayDisplayName('LARGE_CAP'), 'Large Cap');
    expect(xrayDisplayName('MID_CAP'), 'Mid Cap');
    expect(xrayDisplayName('SMALL_CAP'), 'Small Cap');
    expect(xrayDisplayName('MICRO_CAP'), 'Micro Cap');
    expect(xrayDisplayName('UNKNOWN'), 'Unknown');
    expect(xrayDisplayName(''), 'Unknown');
    expect(xrayDisplayName('Financial Services'), 'Financial Services');
  });

  testWidgets('X-Ray Cap tab switches weights', (tester) async {
    final intel = PortfolioIntelligence(
      portfolioId: 'p1',
      xray: const PortfolioXray(
        sectorWeights: [XrayWeight(name: 'Sec', weightPct: 10)],
        industryWeights: [XrayWeight(name: 'Ind', weightPct: 20)],
        marketCapWeights: [XrayWeight(name: 'Large Cap', weightPct: 70)],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioIntelligenceProvider('p1').overrideWith(
            (ref) async => intel,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 520,
              child: PortfolioXrayPanel(portfolioId: 'p1', minHeight: 480),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Cap'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Large Cap'), findsWidgets);
    expect(find.text('70.0%'), findsWidgets);
  });

  testWidgets('X-Ray Cap API keys render as display labels', (tester) async {
    final intel = PortfolioIntelligence(
      portfolioId: 'p1',
      xray: const PortfolioXray(
        sectorWeights: [XrayWeight(name: 'IT', weightPct: 10)],
        industryWeights: [XrayWeight(name: 'Software', weightPct: 10)],
        marketCapWeights: [
          XrayWeight(name: 'LARGE_CAP', weightPct: 37.3, valueInr: 350000),
          XrayWeight(name: 'MID_CAP', weightPct: 22.0, valueInr: 200000),
          XrayWeight(name: 'UNKNOWN', weightPct: 5.0, valueInr: 40000),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioIntelligenceProvider('p1').overrideWith(
            (ref) async => intel,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 520,
              child: PortfolioXrayPanel(
                portfolioId: 'p1',
                minHeight: 480,
                fillHeight: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Cap'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('LARGE_CAP'), findsNothing);
    expect(find.text('Large Cap'), findsWidgets);
    expect(find.text('Mid Cap'), findsWidgets);
    expect(find.text('Unknown'), findsWidgets);
    expect(find.text('37.3%'), findsWidgets);
    expect(find.text('₹3.5L'), findsWidgets);
    expect(find.textContaining('37.3%₹'), findsNothing);
  });

  testWidgets('X-Ray phone swaps Chart/List in-box; web has no swap',
      (tester) async {
    final intel = PortfolioIntelligence(
      portfolioId: 'p1',
      xray: const PortfolioXray(
        sectorWeights: [
          XrayWeight(name: 'Healthcare', weightPct: 9.9, valueInr: 91700),
          XrayWeight(name: 'IT', weightPct: 18.2, valueInr: 170000),
        ],
        industryWeights: [],
        marketCapWeights: [],
      ),
    );

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioIntelligenceProvider('p1').overrideWith(
            (ref) async => intel,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortfolioXrayPanel(portfolioId: 'p1', minHeight: 320),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Chart'), findsOneWidget);
    expect(find.text('List'), findsOneWidget);
    // Chart pane: sector names live in list, not on chart center by default.
    expect(find.text('Healthcare'), findsNothing);

    // Chart tap must not auto-switch to List (user owns Chart/List).
    await tester.tap(find.byType(CustomPaint).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Chart'), findsOneWidget);
    expect(find.text('Healthcare'), findsNothing);

    await tester.tap(find.text('List'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Healthcare'), findsOneWidget);
    expect(find.text('IT'), findsOneWidget);

    await tester.tap(find.text('Chart'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Healthcare'), findsNothing);

    // Wide viewport: side-by-side, no Chart/List swap chrome.
    tester.view.physicalSize = const Size(900, 800);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioIntelligenceProvider('p1').overrideWith(
            (ref) async => intel,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 520,
              child: PortfolioXrayPanel(portfolioId: 'p1', minHeight: 480),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Chart'), findsNothing);
    expect(find.text('List'), findsNothing);
    expect(find.text('Healthcare'), findsOneWidget);
  });

  testWidgets('X-Ray +N more opens full holdings sheet', (tester) async {
    final holdings = List.generate(
      7,
      (i) => _holding(
        symbol: 'SYM$i',
        sector: 'Financial Services',
        weight: 5.0 - (i * 0.3),
        value: 100000.0 - (i * 5000),
      ),
    );
    final intel = PortfolioIntelligence(
      portfolioId: 'p1',
      xray: PortfolioXray(
        sectorWeights: [
          XrayWeight(
            name: 'Financial Services',
            weightPct: 31.4,
            valueInr: 650000,
          ),
        ],
        industryWeights: const [],
        marketCapWeights: const [],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioIntelligenceProvider('p1').overrideWith(
            (ref) async => intel,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 640,
              child: PortfolioXrayPanel(
                portfolioId: 'p1',
                minHeight: 480,
                holdingsOverride: holdings,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('+2 more'), findsOneWidget);
    expect(find.text('SYM0'), findsOneWidget);
    expect(find.text('SYM5'), findsNothing);

    await tester.ensureVisible(find.text('+2 more'));
    await tester.pump();
    await tester.tap(find.text('+2 more'), warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Financial Services'), findsWidgets);
    expect(find.textContaining('7 holdings'), findsOneWidget);
    expect(find.text('SYM5'), findsOneWidget);
    expect(find.text('SYM6'), findsOneWidget);
  });

  testWidgets('compact Movers uses Gainers|Losers tabs', (tester) async {
    final movers = Movers(
      topGainers: [
        Stock(
          symbol: 'AAA',
          companyName: 'A',
          lastPrice: 100,
          changeAmount: 2,
          changePercent: 2,
          sector: 'IT',
        ),
        Stock(
          symbol: 'BBB',
          companyName: 'B',
          lastPrice: 50,
          changeAmount: 1,
          changePercent: 1,
          sector: 'IT',
        ),
      ],
      topLosers: [
        Stock(
          symbol: 'CCC',
          companyName: 'C',
          lastPrice: 40,
          changeAmount: -1,
          changePercent: -2.5,
          sector: 'Energy',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MoversWidget(movers: movers, compact: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Top Movers'), findsOneWidget);
    expect(find.text('Gainers (2)'), findsOneWidget);
    expect(find.text('Losers (1)'), findsOneWidget);
    expect(find.text('AAA'), findsOneWidget);
    expect(find.text('CCC'), findsNothing);

    await tester.tap(find.text('Losers (1)'));
    await tester.pumpAndSettle();
    expect(find.text('CCC'), findsOneWidget);
  });

  testWidgets('Risk empty findings shows primary-axis severity pills',
      (tester) async {
    final intel = PortfolioIntelligence(
      portfolioId: 'p1',
      risk: PortfolioRisk(
        axes: const [
          RiskAxis(id: 'beta', riskScore: 68),
          RiskAxis(id: 'volatility', riskScore: 72),
          RiskAxis(id: 'liquidity', riskScore: 45),
          RiskAxis(id: 'concentration', riskScore: 10),
          RiskAxis(id: 'diversification', riskScore: 0),
          RiskAxis(id: 'sector', riskScore: 55),
        ],
        findings: const [],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioIntelligenceProvider('p1').overrideWith(
            (ref) async => intel,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortfolioRiskRadarCard(portfolioId: 'p1'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('No material risk findings'), findsNothing);
    expect(find.text('Volatility'), findsNothing);
    expect(find.text('Concentration risk'), findsWidgets);
    expect(find.text('Sector risk'), findsWidgets);
    expect(find.text('Diversification risk'), findsWidgets);
    expect(find.text('Liquidity risk'), findsWidgets);
    expect(
      find.text('Scores are 0–100. Higher means more risk.'),
      findsOneWidget,
    );
    expect(find.text('Higher scores mean more risk.'), findsNothing);
    expect(find.text('45 / 100'), findsWidgets);
    expect(find.text('10 / 100'), findsWidgets);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(find.text('Medium Risk'), findsOneWidget);
    expect(find.text('Score'), findsNothing);
    expect(find.text('View Risk Analysis →'), findsNothing);
    expect(find.textContaining('Key Insight'), findsNothing);
    expect(
      find.text('How your portfolio risk is distributed'),
      findsNothing,
    );
    expect(
      find.textContaining('Tap a factor to learn'),
      findsNothing,
    );

    await tester.tap(find.text('Liquidity risk').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Key Insight'), findsOneWidget);
    expect(find.text('What it means'), findsNothing);
    expect(find.text('Good to know'), findsNothing);
    expect(find.textContaining('cash'), findsOneWidget);

    // Paint order: Concentration above Sector above Diversification above Liquidity.
    final concY = tester.getTopLeft(find.text('Concentration risk').first).dy;
    final sectorY = tester.getTopLeft(find.text('Sector risk').first).dy;
    final divY = tester.getTopLeft(find.text('Diversification risk').first).dy;
    final liqY = tester.getTopLeft(find.text('Liquidity risk').first).dy;
    expect(concY, lessThan(sectorY));
    expect(sectorY, lessThan(divY));
    expect(divY, lessThan(liqY));
  });

  testWidgets('Risk finding attaches into Sector expand body', (tester) async {
    final intel = PortfolioIntelligence(
      portfolioId: 'p1',
      risk: PortfolioRisk(
        axes: const [
          RiskAxis(id: 'concentration', riskScore: 40),
          RiskAxis(id: 'sector', riskScore: 50),
          RiskAxis(id: 'diversification', riskScore: 20),
          RiskAxis(id: 'liquidity', riskScore: 30),
        ],
        findings: const [
          RiskFinding(
            code: 'SECTOR_HIGH',
            label: 'Financial Services 31.4%',
            severity: 'HIGH',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioIntelligenceProvider('p1').overrideWith(
            (ref) async => intel,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortfolioRiskRadarCard(portfolioId: 'p1'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Sector risk'), findsWidgets);
    expect(find.text('Financial Services 31.4%'), findsNothing);
    expect(find.textContaining('Key Insight'), findsNothing);
    expect(find.text('Medium Risk'), findsOneWidget);

    await tester.tap(find.text('Sector risk').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Key Insight'), findsOneWidget);
    expect(find.text('Financial Services 31.4%'), findsOneWidget);
  });

  test('healthBandForScore mirrors backend bands', () {
    expect(healthBandForScore(39), 'Critical');
    expect(healthBandForScore(64), 'Watch');
    expect(healthBandForScore(84), 'Healthy');
    expect(healthBandForScore(85), 'Strong');
  });

  test('healthStatusLabel maps bands for UI copy', () {
    expect(healthStatusLabel(100), 'Excellent');
    expect(healthStatusLabel(90), 'Strong');
    expect(healthStatusLabel(55), 'Needs Attention');
    expect(healthStatusLabel(80), 'Healthy');
  });

  test('countStrongHealthFactors uses Strong band only', () {
    final factors = [
      const HealthComponent(id: 'diversification', score: 100),
      const HealthComponent(id: 'concentration', score: 90),
      const HealthComponent(id: 'liquidity', score: 55),
      const HealthComponent(id: 'allocation', score: 100),
      const HealthComponent(id: 'risk_resilience', score: 80),
    ];
    expect(countStrongHealthFactors(factors), 3);
    expect(selectOverviewHealthFactors(factors).length, 5);
  });

  test('healthReasonDisplay polishes backend reason text only', () {
    expect(
      healthReasonDisplay('Top1 4.87%, max sector 19.45%'),
      'Top holding 4.87% • Max sector 19.45%',
    );
    expect(
      healthReasonDisplay('Blend of concentration / vol / beta'),
      'Blend of concentration / volatility / beta',
    );
  });

  testWidgets('Health overview shows five factors inline without popup',
      (tester) async {
    final intel = PortfolioIntelligence(
      portfolioId: 'p1',
      health: PortfolioHealth(
        score: 88,
        band: 'Strong',
        components: const [
          HealthComponent(
            id: 'diversification',
            score: 100,
            severity: 'OK',
            reason: 'Names 110, sectors 12',
          ),
          HealthComponent(
            id: 'concentration',
            score: 90,
            severity: 'OK',
            reason: 'Top1 4.87%, max sector 19.45%',
          ),
          HealthComponent(
            id: 'liquidity',
            score: 55,
            severity: 'FOCUS',
            reason: 'Liquid share 54.65%',
          ),
          HealthComponent(
            id: 'allocation',
            score: 100,
            severity: 'OK',
            reason: 'Max sector 19.45%',
          ),
          HealthComponent(
            id: 'risk_resilience',
            score: 80,
            severity: 'OK',
            reason: 'Blend of concentration / vol / beta',
          ),
          HealthComponent(id: 'extra', score: 40),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioIntelligenceProvider('p1').overrideWith(
            (ref) async => intel,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 900,
                child: PortfolioHealthCard(portfolioId: 'p1'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('88'), findsWidgets);
    expect(find.text('/ 100'), findsOneWidget);
    expect(find.text('Strong'), findsWidgets);
    expect(find.text('5'), findsWidgets);
    expect(find.text('Health Factors'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('Diversification'), findsOneWidget);
    expect(find.text('Concentration'), findsOneWidget);
    expect(find.text('Liquidity'), findsOneWidget);
    expect(find.text('Allocation'), findsOneWidget);
    expect(find.text('Risk Resilience'), findsOneWidget);
    expect(find.textContaining('Names 110'), findsOneWidget);
    expect(find.textContaining('Liquid share 54.65%'), findsOneWidget);
    expect(find.text('View Details →'), findsNothing);
    expect(find.text('Health Details'), findsNothing);
    expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    expect(find.textContaining('2 Watch'), findsNothing);
    expect(find.text('Higher factor scores mean healthier.'), findsNothing);
    expect(find.text('Extra'), findsNothing);
    expect(find.text('Excellent'), findsWidgets);
    expect(find.text('Needs Attention'), findsOneWidget);
  });

  testWidgets('Health Strong count changes with factor scores', (tester) async {
    final intel = PortfolioIntelligence(
      portfolioId: 'p1',
      health: PortfolioHealth(
        score: 70,
        band: 'Healthy',
        components: const [
          HealthComponent(id: 'diversification', score: 90),
          HealthComponent(id: 'concentration', score: 88),
          HealthComponent(id: 'liquidity', score: 50),
          HealthComponent(id: 'allocation', score: 60),
          HealthComponent(id: 'risk_resilience', score: 40),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioIntelligenceProvider('p1').overrideWith(
            (ref) async => intel,
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortfolioHealthCard(portfolioId: 'p1'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('2'), findsWidgets);
    expect(find.text('Strong'), findsWidgets);
    expect(find.text('View Details →'), findsNothing);
  });

  testWidgets('What-If shows compact After Simulation placeholder before run',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioHoldingsProvider('p1').overrideWith(
            (ref) async => PortfolioHoldings(
              holdings: const [],
              lastUpdated: DateTime(2026, 1, 1),
            ),
          ),
          portfolioIntelligenceProvider('p1').overrideWith(
            (ref) async => const PortfolioIntelligence(
              portfolioId: 'p1',
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortfolioWhatIfCard(
                portfolioId: 'p1',
                initiallyExpanded: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('After Simulation'), findsOneWidget);
    expect(
      find.text('Run simulation to see portfolio impact'),
      findsOneWidget,
    );
    expect(find.text('Simulate'), findsOneWidget);
  });

  testWidgets('What-If rejects empty Simulate', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioHoldingsProvider('p1').overrideWith(
            (ref) async => PortfolioHoldings(
              holdings: const [],
              lastUpdated: DateTime(2026, 1, 1),
            ),
          ),
          portfolioIntelligenceProvider('p1').overrideWith(
            (ref) async => const PortfolioIntelligence(
              portfolioId: 'p1',
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortfolioWhatIfCard(
                portfolioId: 'p1',
                initiallyExpanded: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simulate'));
    await tester.pump();
    expect(find.text('Enter a stock / ETF symbol'), findsOneWidget);
  });

  testWidgets('What-If rejects weight over 100', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioHoldingsProvider('p1').overrideWith(
            (ref) async => PortfolioHoldings(
              holdings: const [],
              lastUpdated: DateTime(2026, 1, 1),
            ),
          ),
          portfolioIntelligenceProvider('p1').overrideWith(
            (ref) async => const PortfolioIntelligence(
              portfolioId: 'p1',
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortfolioWhatIfCard(
                portfolioId: 'p1',
                initiallyExpanded: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modify Holding'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'RELIANCE');
    await tester.enterText(find.byType(TextField).at(1), '150');
    await tester.tap(find.text('Simulate'));
    await tester.pump();
    expect(find.text('Target weight % must be ≤ 100'), findsOneWidget);
    // SmartSearchAnchor schedules a 250ms overlay teardown on focus loss.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('X-Ray Cap expand shows Cap breakdown unavailable without topStocks',
      (tester) async {
    final intel = PortfolioIntelligence(
      portfolioId: 'p1',
      xray: const PortfolioXray(
        sectorWeights: [],
        industryWeights: [],
        marketCapWeights: [
          XrayWeight(name: 'Large Cap', weightPct: 70, valueInr: 700000),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioIntelligenceProvider('p1').overrideWith(
            (ref) async => intel,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 640,
              child: PortfolioXrayPanel(
                portfolioId: 'p1',
                minHeight: 480,
                holdingsOverride: [
                  _holding(
                    symbol: 'AAA',
                    sector: 'IT',
                    weight: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Cap'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down).first);
    await tester.pump();

    expect(find.text('Cap breakdown unavailable'), findsOneWidget);
    expect(find.text('No holdings for this group'), findsNothing);
  });

  testWidgets('Stress rejects zero shock before API', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioHoldingsProvider('p1').overrideWith(
            (ref) async => PortfolioHoldings(
              holdings: [
                _holding(symbol: 'IT', sector: 'IT', weight: 10),
              ],
              lastUpdated: DateTime(2026, 1, 1),
            ),
          ),
          portfolioIntelligenceProvider('p1').overrideWith(
            (ref) async => const PortfolioIntelligence(
              portfolioId: 'p1',
              xray: PortfolioXray(
                sectorWeights: [XrayWeight(name: 'IT', weightPct: 10)],
                industryWeights: [],
                marketCapWeights: [],
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PortfolioStressCard(
                portfolioId: 'p1',
                initiallyExpanded: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Run custom'), findsOneWidget);
    final fields = find.byType(TextField);
    expect(fields, findsAtLeastNWidgets(2));
    await tester.enterText(fields.at(0), 'IT');
    await tester.enterText(fields.at(1), '0');
    await tester.tap(find.text('Run custom'));
    await tester.pump();

    expect(find.text('Shock % must be non-zero'), findsOneWidget);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump(const Duration(milliseconds: 300));
  });

  test('What-If switch rejects same from/to sector', () {
    expect(
      validateWhatIfSwitchAllocation(
        fromSector: 'IT',
        toSector: 'IT',
        moveWeightPct: '5',
      ),
      'From and to sectors must differ',
    );
    expect(
      validateWhatIfSwitchAllocation(
        fromSector: 'IT',
        toSector: 'Energy',
        moveWeightPct: '5',
      ),
      isNull,
    );
  });

  test('isUsableIntelligenceSectorLabel filters junk', () {
    expect(isUsableIntelligenceSectorLabel('IT'), isTrue);
    expect(isUsableIntelligenceSectorLabel('unknown'), isFalse);
    expect(isUsableIntelligenceSectorLabel('—'), isFalse);
    expect(isUsableIntelligenceSectorLabel('  '), isFalse);
  });

  testWidgets('Intelligence sheet Close pops dialog, keeps home', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showIntelligenceSheet(
                  context: context,
                  title: 'Risk Analysis',
                  body: const Text('Sheet body content'),
                ),
                child: const Text('Open sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Open sheet'), findsOneWidget);
    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    expect(find.text('Risk Analysis'), findsOneWidget);
    expect(find.text('Sheet body content'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Risk Analysis'), findsNothing);
    expect(find.text('Sheet body content'), findsNothing);
    expect(find.text('Open sheet'), findsOneWidget);
  });
}
