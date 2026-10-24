import 'dart:io';

import 'package:am_design_system/am_design_system.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_holding.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_summary.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/mobile/widgets/portfolio_holdings_widget.dart';
import 'package:am_portfolio_ui/features/portfolio/providers/portfolio_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

PortfolioHolding _holding({
  required String symbol,
  required double investedAmount,
  required double avgPrice,
  required double quantity,
}) {
  return PortfolioHolding(
    id: symbol,
    symbol: symbol,
    name: symbol,
    companyName: '$symbol Ltd',
    sector: 'IT',
    industry: 'Software',
    quantity: quantity,
    avgPrice: avgPrice,
    currentPrice: 123.45,
    investedAmount: investedAmount,
    currentValue: 1234.56,
    todayChange: 1.2,
    todayChangePercentage: 0.1,
    totalGainLoss: 0,
    totalGainLossPercentage: 0,
    portfolioWeight: 10,
  );
}

Finder _cardFor(String symbol) => find.ancestor(
      of: find.text(symbol),
      matching: find.byType(InvestmentCard),
    );

Future<void> _pumpHoldings(
  WidgetTester tester, {
  required List<PortfolioHolding> holdings,
  DateTime? asOf,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        portfolioHoldingsProvider('p1').overrideWith(
          (ref) async => PortfolioHoldings(
            holdings: holdings,
            lastUpdated: DateTime(2026, 10, 21, 17, 38),
            asOf: asOf ?? DateTime(2026, 10, 21, 17, 38),
          ),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: PortfolioHoldingsWidget(
            portfolioId: 'p1',
            showNewsSection: false,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  test('PortfolioHolding.hasCostBasis is false only when both costs are zero',
      () {
    expect(
      _holding(
        symbol: 'MAIL',
        investedAmount: 0,
        avgPrice: 0,
        quantity: 5,
      ).hasCostBasis,
      isFalse,
    );
    expect(
      _holding(
        symbol: 'TCS',
        investedAmount: 1000,
        avgPrice: 0,
        quantity: 5,
      ).hasCostBasis,
      isTrue,
    );
    expect(
      _holding(
        symbol: 'INFY',
        investedAmount: 0,
        avgPrice: 12,
        quantity: 5,
      ).hasCostBasis,
      isTrue,
    );
  });

  test('page-level holdings stamp still formats As of', () {
    final holdings = PortfolioHoldings(
      holdings: const [],
      lastUpdated: DateTime(2026, 10, 21, 17, 38),
      asOf: DateTime(2026, 10, 21, 17, 38),
    );
    expect(holdings.priceLabel, contains('As of'));
    expect(holdings.priceLabel, contains('2026-10-21'));

    final summary = PortfolioSummary.empty().copyWith(
      lastUpdated: DateTime(2026, 10, 21, 17, 38),
      asOf: DateTime(2026, 10, 21, 17, 38),
    );
    expect(summary.priceLabel, contains('As of 2026-10-21'));
  });

  test('mobile screen still renders the page-level stamp', () {
    final source = File(
      'lib/features/portfolio/presentation/mobile/portfolio_mobile_screen.dart',
    ).readAsStringSync();
    expect(source.contains('_buildStickyAsOfLabel'), isTrue);
    expect(source.contains('summary.priceLabel'), isTrue);
  });

  testWidgets('holdings cards drop per-row As of and hide zero cost',
      (tester) async {
    await _pumpHoldings(
      tester,
      holdings: [
        _holding(
          symbol: 'MAIL',
          investedAmount: 0,
          avgPrice: 0,
          quantity: 7,
        ),
        _holding(
          symbol: 'TCS',
          investedAmount: 2500,
          avgPrice: 250,
          quantity: 4,
        ),
      ],
    );

    expect(find.textContaining('As of'), findsNothing);
    expect(find.textContaining('2026-10-21'), findsNothing);
    expect(find.textContaining('17:38'), findsNothing);

    final mailCard = _cardFor('MAIL');
    expect(
      find.descendant(of: mailCard, matching: find.textContaining('Inv.')),
      findsNothing,
    );
    expect(
      find.descendant(of: mailCard, matching: find.textContaining('Avg')),
      findsNothing,
    );
    expect(
      find.descendant(of: mailCard, matching: find.text('7')),
      findsOneWidget,
    );

    final tcsCard = _cardFor('TCS');
    expect(
      find.descendant(of: tcsCard, matching: find.textContaining('Inv.')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tcsCard, matching: find.textContaining('Avg')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tcsCard, matching: find.text('4')),
      findsOneWidget,
    );

    final mailH = tester.getSize(mailCard).height;
    final tcsH = tester.getSize(tcsCard).height;
    expect(mailH, lessThan(tcsH));
    final qtyDy = tester
        .getCenter(find.descendant(of: mailCard, matching: find.text('7')))
        .dy;
    final pnlDy = tester
        .getCenter(
          find.descendant(of: mailCard, matching: find.text('+₹1.20')),
        )
        .dy;
    expect((qtyDy - pnlDy).abs(), lessThan(8));
  });
}
