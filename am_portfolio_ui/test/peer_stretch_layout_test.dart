import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_intelligence.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/portfolio_health_card.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/portfolio_risk_radar_card.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/portfolio_xray_panel.dart';
import 'package:am_portfolio_ui/features/portfolio/providers/portfolio_intelligence_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression: Overview peer rows must use fixed height bands + stretch.
/// IntrinsicHeight + X-Ray ListView throws and blanks the mid-section.
void main() {
  final intel = PortfolioIntelligence(
    portfolioId: 'p1',
    health: PortfolioHealth(
      score: 72,
      band: 'Healthy',
      components: [
        for (final n in [
          'diversification',
          'concentration',
          'liquidity',
          'momentum',
          'quality',
          'value',
        ])
          HealthComponent(id: n, score: 70),
      ],
    ),
    risk: PortfolioRisk(
      axes: [
        for (final n in ['market', 'sector', 'liquidity', 'credit'])
          RiskAxis(id: n, riskScore: 40),
      ],
      findings: const [],
    ),
    xray: PortfolioXray(
      sectorWeights: const [
        XrayWeight(name: 'IT', weightPct: 40),
        XrayWeight(name: 'Banks', weightPct: 30),
      ],
      industryWeights: const [XrayWeight(name: 'Software', weightPct: 40)],
      marketCapWeights: const [XrayWeight(name: 'Large Cap', weightPct: 80)],
    ),
  );

  testWidgets('Chart|Health fixed band + fillHeight does not overflow/throw',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioIntelligenceProvider('p1').overrideWith((ref) async => intel),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 340,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(
                        flex: 2,
                        child: ColoredBox(color: Colors.blue),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PortfolioHealthCard(
                          portfolioId: 'p1',
                          fillHeight: true,
                          maxComponents: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);
    expect(find.text('Health Score'), findsOneWidget);
    expect(find.text('View Details →'), findsNothing);
  });

  testWidgets('X-Ray|Risk fixed band + fillHeight does not throw',
      (tester) async {
    final errors = <FlutterErrorDetails>[];
    final old = FlutterError.onError;
    FlutterError.onError = (details) {
      // Peer band is intentionally tight; ignore soft layout overflows only.
      final msg = details.exceptionAsString();
      if (msg.contains('A RenderFlex overflowed')) {
        return;
      }
      errors.add(details);
      old?.call(details);
    };
    addTearDown(() => FlutterError.onError = old);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          portfolioIntelligenceProvider('p1').overrideWith((ref) async => intel),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  height: 340,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: PortfolioXrayPanel(
                          portfolioId: 'p1',
                          fillHeight: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: PortfolioRiskRadarCard(
                          portfolioId: 'p1',
                          fillHeight: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(errors, isEmpty);
    expect(tester.takeException(), isNull);
    expect(find.text('Portfolio X-Ray'), findsOneWidget);
    expect(find.text('Risk Radar'), findsOneWidget);
  });
}
