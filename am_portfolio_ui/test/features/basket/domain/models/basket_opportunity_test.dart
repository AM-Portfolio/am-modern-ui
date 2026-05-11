import 'package:flutter_test/flutter_test.dart';
import 'package:am_portfolio_ui/features/basket/domain/models/basket_opportunity.dart';

void main() {
  group('ItemStatus enum', () {
    test('contains held, missing, and substitute values', () {
      expect(ItemStatus.values, containsAll([
        ItemStatus.held,
        ItemStatus.missing,
        ItemStatus.substitute,
      ]));
    });

    test('name values match expected strings', () {
      expect(ItemStatus.held.name, equals('held'));
      expect(ItemStatus.missing.name, equals('missing'));
      expect(ItemStatus.substitute.name, equals('substitute'));
    });
  });

  group('Alternative', () {
    group('fromJson', () {
      test('parses all fields correctly', () {
        final json = {
          'symbol': 'AAPL',
          'isin': 'US0378331005',
          'userWeight': 5.5,
        };
        final alt = Alternative.fromJson(json);

        expect(alt.symbol, equals('AAPL'));
        expect(alt.isin, equals('US0378331005'));
        expect(alt.userWeight, equals(5.5));
      });

      test('defaults symbol to Unknown when missing', () {
        final alt = Alternative.fromJson({'isin': 'US123', 'userWeight': 1.0});
        expect(alt.symbol, equals('Unknown'));
      });

      test('defaults isin to empty string when missing', () {
        final alt = Alternative.fromJson({'symbol': 'MSFT', 'userWeight': 2.0});
        expect(alt.isin, equals(''));
      });

      test('defaults userWeight to 0.0 when missing', () {
        final alt = Alternative.fromJson({'symbol': 'TSLA', 'isin': 'US88160R1014'});
        expect(alt.userWeight, equals(0.0));
      });
    });

    group('toJson', () {
      test('serializes all fields correctly', () {
        const alt = Alternative(symbol: 'RELIANCE', isin: 'INE002A01018', userWeight: 3.14);
        final json = alt.toJson();

        expect(json['symbol'], equals('RELIANCE'));
        expect(json['isin'], equals('INE002A01018'));
        expect(json['userWeight'], equals(3.14));
      });

      test('toJson only includes symbol, isin, userWeight keys', () {
        const alt = Alternative(symbol: 'TCS', isin: 'INE467B01029', userWeight: 0.0);
        final json = alt.toJson();

        expect(json.keys.toSet(), equals({'symbol', 'isin', 'userWeight'}));
      });
    });

    group('copyWith', () {
      test('returns a new instance with updated symbol', () {
        const original = Alternative(symbol: 'A', isin: 'isin1', userWeight: 1.0);
        final copy = original.copyWith(symbol: 'B');

        expect(copy.symbol, equals('B'));
        expect(copy.isin, equals('isin1'));
        expect(copy.userWeight, equals(1.0));
      });

      test('returns a new instance with updated isin', () {
        const original = Alternative(symbol: 'X', isin: 'old', userWeight: 2.0);
        final copy = original.copyWith(isin: 'new');

        expect(copy.isin, equals('new'));
        expect(copy.symbol, equals('X'));
      });

      test('returns a new instance with updated userWeight', () {
        const original = Alternative(symbol: 'Y', isin: 'isin2', userWeight: 0.5);
        final copy = original.copyWith(userWeight: 9.9);

        expect(copy.userWeight, equals(9.9));
      });

      test('with no arguments returns identical field values', () {
        const original = Alternative(symbol: 'Z', isin: 'isin3', userWeight: 7.0);
        final copy = original.copyWith();

        expect(copy.symbol, equals(original.symbol));
        expect(copy.isin, equals(original.isin));
        expect(copy.userWeight, equals(original.userWeight));
      });
    });
  });

  group('BasketItem', () {
    group('fromJson', () {
      test('parses all required fields', () {
        final json = {
          'stockSymbol': 'INFY',
          'isin': 'INE009A01021',
          'sector': 'IT',
          'status': 'HELD',
          'etfWeight': 8.5,
          'userWeight': 7.2,
          'replicaWeight': 8.0,
          'buyQuantity': 10.0,
          'lastPrice': 1500.0,
        };
        final item = BasketItem.fromJson(json);

        expect(item.stockSymbol, equals('INFY'));
        expect(item.isin, equals('INE009A01021'));
        expect(item.sector, equals('IT'));
        expect(item.status, equals(ItemStatus.held));
        expect(item.etfWeight, equals(8.5));
        expect(item.userWeight, equals(7.2));
        expect(item.buyQuantity, equals(10.0));
        expect(item.lastPrice, equals(1500.0));
      });

      test('parses status case-insensitively - lowercase held', () {
        final json = {
          'stockSymbol': 'TCS',
          'isin': 'INE467B01029',
          'sector': 'IT',
          'status': 'held',
        };
        final item = BasketItem.fromJson(json);
        expect(item.status, equals(ItemStatus.held));
      });

      test('parses status case-insensitively - uppercase MISSING', () {
        final json = {
          'stockSymbol': 'WIPRO',
          'isin': 'INE075A01022',
          'sector': 'IT',
          'status': 'MISSING',
        };
        final item = BasketItem.fromJson(json);
        expect(item.status, equals(ItemStatus.missing));
      });

      test('parses status case-insensitively - mixed case Substitute', () {
        final json = {
          'stockSymbol': 'HCLTECH',
          'isin': 'INE860A01027',
          'sector': 'IT',
          'status': 'Substitute',
        };
        final item = BasketItem.fromJson(json);
        expect(item.status, equals(ItemStatus.substitute));
      });

      test('falls back to missing for unknown status value', () {
        final json = {
          'stockSymbol': 'UNKNOWN',
          'isin': '',
          'sector': 'Unknown',
          'status': 'INVALID_STATUS',
        };
        final item = BasketItem.fromJson(json);
        expect(item.status, equals(ItemStatus.missing));
      });

      test('falls back to missing when status is null', () {
        final json = {
          'stockSymbol': 'TESTSTOCK',
          'isin': '',
          'sector': 'Finance',
          'status': null,
        };
        final item = BasketItem.fromJson(json);
        expect(item.status, equals(ItemStatus.missing));
      });

      test('parses alternatives list', () {
        final json = {
          'stockSymbol': 'RELIANCE',
          'isin': 'INE002A01018',
          'sector': 'Energy',
          'status': 'MISSING',
          'alternatives': [
            {'symbol': 'ALT1', 'isin': 'isin1', 'userWeight': 1.0},
            {'symbol': 'ALT2', 'isin': 'isin2', 'userWeight': 2.0},
          ],
        };
        final item = BasketItem.fromJson(json);
        expect(item.alternatives.length, equals(2));
        expect(item.alternatives[0].symbol, equals('ALT1'));
        expect(item.alternatives[1].symbol, equals('ALT2'));
      });

      test('defaults alternatives to empty list when absent', () {
        final json = {
          'stockSymbol': 'SBI',
          'isin': 'INE062A01020',
          'sector': 'Banking',
          'status': 'HELD',
        };
        final item = BasketItem.fromJson(json);
        expect(item.alternatives, isEmpty);
      });

      test('defaults numeric fields to 0.0 when absent', () {
        final json = {
          'stockSymbol': 'HDFC',
          'isin': 'INE001A01036',
          'sector': 'Finance',
          'status': 'HELD',
        };
        final item = BasketItem.fromJson(json);
        expect(item.etfWeight, equals(0.0));
        expect(item.userWeight, equals(0.0));
        expect(item.replicaWeight, equals(0.0));
        expect(item.buyQuantity, equals(0.0));
      });

      test('defaults stockSymbol to Unknown when absent', () {
        final json = {
          'isin': '',
          'sector': 'Unknown',
          'status': 'HELD',
        };
        final item = BasketItem.fromJson(json);
        expect(item.stockSymbol, equals('Unknown'));
      });

      test('parses optional heldQuantity and heldAveragePrice', () {
        final json = {
          'stockSymbol': 'ICICI',
          'isin': 'INE090A01021',
          'sector': 'Banking',
          'status': 'HELD',
          'heldQuantity': 50.0,
          'heldAveragePrice': 800.0,
        };
        final item = BasketItem.fromJson(json);
        expect(item.heldQuantity, equals(50.0));
        expect(item.heldAveragePrice, equals(800.0));
      });

      test('heldQuantity and heldAveragePrice are null when absent', () {
        final json = {
          'stockSymbol': 'AXIS',
          'isin': 'INE238A01034',
          'sector': 'Banking',
          'status': 'MISSING',
        };
        final item = BasketItem.fromJson(json);
        expect(item.heldQuantity, isNull);
        expect(item.heldAveragePrice, isNull);
      });
    });

    group('toJson', () {
      test('serializes status as uppercase string', () {
        const item = BasketItem(
          stockSymbol: 'TCS',
          isin: 'INE467B01029',
          sector: 'IT',
          status: ItemStatus.held,
        );
        final json = item.toJson();
        expect(json['status'], equals('HELD'));
      });

      test('status missing serializes to MISSING uppercase', () {
        const item = BasketItem(
          stockSymbol: 'X',
          isin: '',
          sector: 'Unknown',
          status: ItemStatus.missing,
        );
        final json = item.toJson();
        expect(json['status'], equals('MISSING'));
      });

      test('status substitute serializes to SUBSTITUTE uppercase', () {
        const item = BasketItem(
          stockSymbol: 'Y',
          isin: '',
          sector: 'Unknown',
          status: ItemStatus.substitute,
        );
        final json = item.toJson();
        expect(json['status'], equals('SUBSTITUTE'));
      });
    });
  });

  group('BasketOpportunity', () {
    group('fromJson', () {
      test('parses all scalar fields', () {
        final json = {
          'etfIsin': 'INF204KB12I2',
          'etfName': 'Nifty 50',
          'matchScore': 85.5,
          'replicaScore': 92.0,
          'readyToReplicate': true,
          'totalItems': 50,
          'heldCount': 30,
          'missingCount': 20,
          'totalPortfolioValue': 1000000.0,
          'composition': [],
          'buyList': [],
        };
        final opportunity = BasketOpportunity.fromJson(json);

        expect(opportunity.etfIsin, equals('INF204KB12I2'));
        expect(opportunity.etfName, equals('Nifty 50'));
        expect(opportunity.matchScore, equals(85.5));
        expect(opportunity.replicaScore, equals(92.0));
        expect(opportunity.readyToReplicate, isTrue);
        expect(opportunity.totalItems, equals(50));
        expect(opportunity.heldCount, equals(30));
        expect(opportunity.missingCount, equals(20));
        expect(opportunity.totalPortfolioValue, equals(1000000.0));
      });

      test('parses composition list with BasketItems', () {
        final json = {
          'etfIsin': 'TEST',
          'etfName': 'Test ETF',
          'composition': [
            {
              'stockSymbol': 'INFY',
              'isin': 'INE009A01021',
              'sector': 'IT',
              'status': 'HELD',
            },
            {
              'stockSymbol': 'TCS',
              'isin': 'INE467B01029',
              'sector': 'IT',
              'status': 'MISSING',
            },
          ],
          'buyList': [],
        };
        final opportunity = BasketOpportunity.fromJson(json);

        expect(opportunity.composition.length, equals(2));
        expect(opportunity.composition[0].stockSymbol, equals('INFY'));
        expect(opportunity.composition[0].status, equals(ItemStatus.held));
        expect(opportunity.composition[1].stockSymbol, equals('TCS'));
        expect(opportunity.composition[1].status, equals(ItemStatus.missing));
      });

      test('parses buyList with BasketItems', () {
        final json = {
          'etfIsin': 'TEST',
          'etfName': 'Test ETF',
          'composition': [],
          'buyList': [
            {
              'stockSymbol': 'WIPRO',
              'isin': 'INE075A01022',
              'sector': 'IT',
              'status': 'MISSING',
              'etfWeight': 3.5,
            },
          ],
        };
        final opportunity = BasketOpportunity.fromJson(json);

        expect(opportunity.buyList.length, equals(1));
        expect(opportunity.buyList[0].stockSymbol, equals('WIPRO'));
        expect(opportunity.buyList[0].etfWeight, equals(3.5));
      });

      test('defaults composition to empty list when absent', () {
        final json = {
          'etfIsin': 'A',
          'etfName': 'B',
        };
        final opportunity = BasketOpportunity.fromJson(json);
        expect(opportunity.composition, isEmpty);
      });

      test('defaults buyList to empty list when absent', () {
        final json = {
          'etfIsin': 'A',
          'etfName': 'B',
        };
        final opportunity = BasketOpportunity.fromJson(json);
        expect(opportunity.buyList, isEmpty);
      });

      test('totalPortfolioValue is null when absent', () {
        final json = {
          'etfIsin': 'A',
          'etfName': 'B',
        };
        final opportunity = BasketOpportunity.fromJson(json);
        expect(opportunity.totalPortfolioValue, isNull);
      });

      test('defaults numeric scores to 0.0 when absent', () {
        final json = {'etfIsin': 'A', 'etfName': 'B'};
        final opportunity = BasketOpportunity.fromJson(json);
        expect(opportunity.matchScore, equals(0.0));
        expect(opportunity.replicaScore, equals(0.0));
      });

      test('roundtrips via toJson and fromJson', () {
        final original = BasketOpportunity(
          etfIsin: 'INF204KB12I2',
          etfName: 'Nifty 50',
          matchScore: 75.0,
          replicaScore: 80.0,
          readyToReplicate: false,
          totalItems: 10,
          heldCount: 5,
          missingCount: 5,
          totalPortfolioValue: 500000.0,
          composition: [
            const BasketItem(
              stockSymbol: 'INFY',
              isin: 'INE009A01021',
              sector: 'IT',
              status: ItemStatus.held,
              etfWeight: 8.0,
            ),
          ],
          buyList: [],
        );

        final json = original.toJson();
        final restored = BasketOpportunity.fromJson(json);

        expect(restored.etfIsin, equals(original.etfIsin));
        expect(restored.etfName, equals(original.etfName));
        expect(restored.matchScore, equals(original.matchScore));
        expect(restored.totalPortfolioValue, equals(original.totalPortfolioValue));
        expect(restored.composition.length, equals(1));
        expect(restored.composition[0].stockSymbol, equals('INFY'));
        expect(restored.composition[0].status, equals(ItemStatus.held));
      });
    });
  });
}