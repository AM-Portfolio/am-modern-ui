import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Holding _holding({
  required String symbol,
  double investedAmount = 0,
  double avgPrice = 0,
  double quantity = 10,
}) {
  return Holding(
    symbol: symbol,
    sector: 'IT',
    quantity: quantity,
    currentValue: 1000,
    totalGainLoss: 0,
    totalGainLossPercentage: 0,
    todayChange: 1,
    todayChangePercentage: 0.1,
    portfolioWeight: 1,
    investedAmount: investedAmount,
    avgPrice: avgPrice,
    currentPrice: 100,
    companyName: '$symbol Ltd',
  );
}

AdvancedHoldingRow _row({
  required String symbol,
  double investedAmount = 0,
  double avgPrice = 0,
  double quantity = 10,
}) {
  return AdvancedHoldingRow(
    id: symbol,
    symbol: symbol,
    companyName: '$symbol Ltd',
    quantity: quantity,
    avgPrice: avgPrice,
    currentPrice: 100,
    investedAmount: investedAmount,
    currentValue: 1000,
  );
}

Future<void> _pumpCards(WidgetTester tester, List<Holding> holdings) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => CardLayoutBuilder().build(
            context,
            holdings,
            sortBy: HoldingsSortBy.symbol,
            sortAscending: true,
            displayFormat: HoldingsDisplayFormat.value,
            changeType: HoldingsChangeType.daily,
          ),
        ),
      ),
    ),
  );
}

Finder _cardFor(String symbol) => find.ancestor(
      of: find.text(symbol),
      matching: find.byType(InvestmentCard),
    );

void main() {
  group('Holding.hasCostBasis', () {
    test('false when invested and avg are both zero', () {
      expect(_holding(symbol: 'MAIL').hasCostBasis, isFalse);
    });

    test('true when invested is positive', () {
      expect(
        _holding(symbol: 'TCS', investedAmount: 1000).hasCostBasis,
        isTrue,
      );
    });

    test('true when avg is positive', () {
      expect(_holding(symbol: 'TCS', avgPrice: 12.5).hasCostBasis, isTrue);
    });
  });

  group('AdvancedHoldingRow cost display', () {
    test('shows em dash when cost is missing', () {
      final row = _row(symbol: 'MAIL');
      expect(row.hasCostBasis, isFalse);
      expect(row.displayAvgPrice, '—');
      expect(row.displayInvestedAmount, '—');
      expect(row.displayQuantity, isNot(contains('—')));
    });

    test('formats avg and invested when cost exists', () {
      final row = _row(symbol: 'TCS', investedAmount: 1000, avgPrice: 100);
      expect(row.hasCostBasis, isTrue);
      expect(row.displayAvgPrice, isNot('—'));
      expect(row.displayInvestedAmount, isNot('—'));
      expect(row.displayAvgPrice, contains('100'));
    });
  });

  group('CardLayoutBuilder cost row', () {
    testWidgets('hides Inv and Avg when cost is missing, keeps qty',
        (tester) async {
      await _pumpCards(tester, [
        _holding(symbol: 'MAIL', quantity: 7),
      ]);

      expect(find.textContaining('Inv.'), findsNothing);
      expect(find.textContaining('Avg'), findsNothing);
      expect(find.text('7'), findsOneWidget);
      expect(find.textContaining('As of'), findsNothing);
    });

    testWidgets('shows Inv and Avg when cost is present', (tester) async {
      await _pumpCards(tester, [
        _holding(symbol: 'TCS', investedAmount: 2500, avgPrice: 250),
      ]);

      expect(
        find.descendant(
          of: _cardFor('TCS'),
          matching: find.textContaining('Inv.'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _cardFor('TCS'),
          matching: find.textContaining('Avg'),
        ),
        findsOneWidget,
      );
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('zero-cost card is shorter than positive-cost card',
        (tester) async {
      await _pumpCards(tester, [
        _holding(symbol: 'MAIL'),
        _holding(symbol: 'TCS', investedAmount: 2500, avgPrice: 250),
      ]);

      final mailH = tester.getSize(_cardFor('MAIL')).height;
      final tcsH = tester.getSize(_cardFor('TCS')).height;
      expect(mailH, lessThan(tcsH));
    });
  });
}
