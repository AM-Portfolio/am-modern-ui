import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_analytics.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_intelligence.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/intelligence_donut.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/portfolio_risk_radar_card.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/portfolio_stress_card.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/portfolio_what_if_card.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/portfolio_xray_panel.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/movers_widget.dart';
import 'package:am_portfolio_ui/features/portfolio/providers/portfolio_intelligence_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stress presets cover five scenarios', () {
    expect(kStressPresets.length, 5);
    expect(kStressPresets.containsKey('NIFTY_DOWN_10'), isTrue);
    expect(kStressPresets.containsKey('CRASH_2008'), isTrue);
  });

  test('intelligence donut palette has stable colors', () {
    expect(IntelligenceDonut.palette.length, greaterThanOrEqualTo(6));
    expect(intelligenceDonutColor(0), IntelligenceDonut.palette.first);
    expect(intelligenceDonutColor(8), IntelligenceDonut.palette.first);
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
    expect(find.text('Explore Full X-Ray →'), findsOneWidget);
    expect(find.text('Asset Class'), findsNothing);
    expect(find.text('Tap tabs'), findsNothing);
    expect(find.text('True Exposure'), findsOneWidget);

    await tester.tap(find.text('Industry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Banks'), findsWidgets);
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
    expect(find.text('Gainers'), findsOneWidget);
    expect(find.text('Losers'), findsOneWidget);
    expect(find.text('AAA'), findsOneWidget);
    expect(find.text('CCC'), findsNothing);

    await tester.tap(find.text('Losers'));
    await tester.pumpAndSettle();
    expect(find.text('CCC'), findsOneWidget);
  });

  testWidgets('Risk empty findings shows axis-band severity pills',
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
    await tester.pumpAndSettle();

    expect(find.text('No material risk findings'), findsNothing);
    expect(find.text('Volatility'), findsWidgets);
    expect(find.text('72'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('Medium'), findsWidgets);
    expect(find.text('Good'), findsWidgets);
    expect(find.text('Score'), findsNothing);
    expect(find.text('View Risk Analysis →'), findsOneWidget);
  });

  testWidgets('Risk real HIGH finding shows High pill', (tester) async {
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
    await tester.pumpAndSettle();

    expect(find.text('Financial Services'), findsOneWidget);
    expect(find.text('31.4%'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
  });

  testWidgets('What-If shows compact After Simulation placeholder before run',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
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
      const ProviderScope(
        child: MaterialApp(
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
      const ProviderScope(
        child: MaterialApp(
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
  });
}
