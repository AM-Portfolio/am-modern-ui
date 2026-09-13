import 'package:am_market_sdk/market/api.dart' as market;
import 'package:flutter_test/flutter_test.dart';

import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/intelligence_suggest_search.dart';

void main() {
  group('mergePreferFirst', () {
    test('prefers holdings order and dedupes case-insensitively', () {
      final merged = mergePreferFirst(
        ['TCS', 'TITAN'],
        ['tcs', 'TECHM', 'INFY'],
        limit: 8,
      );
      expect(merged, ['TCS', 'TITAN', 'TECHM', 'INFY']);
    });

    test('respects limit', () {
      final merged = mergePreferFirst(
        ['A', 'B'],
        ['C', 'D', 'E'],
        limit: 3,
      );
      expect(merged, ['A', 'B', 'C']);
    });
  });

  group('searchSymbolsHoldingsFirst', () {
    test('returns holdings matches first then market', () async {
      final results = await searchSymbolsHoldingsFirst(
        query: 't',
        holdings: const [
          (symbol: 'TCS', name: 'Tata Consultancy'),
          (symbol: 'TITAN', name: 'Titan'),
          (symbol: 'RELIANCE', name: 'Reliance'),
        ],
        marketSearch: (q) async => [
          labelToSecurityDocument('TCS', companyName: 'Tata Consultancy'),
          labelToSecurityDocument('TECHM', companyName: 'Tech Mahindra'),
          labelToSecurityDocument('TATASTEEL', companyName: 'Tata Steel'),
        ],
        limit: 8,
      );

      expect(
        results.map((d) => d.key?.symbol).toList(),
        ['TCS', 'TITAN', 'TECHM', 'TATASTEEL'],
      );
    });

    test('falls back to holdings when market search fails', () async {
      final results = await searchSymbolsHoldingsFirst(
        query: 't',
        holdings: const [
          (symbol: 'TCS', name: 'Tata Consultancy'),
        ],
        marketSearch: (q) async => throw Exception('network'),
        limit: 8,
      );

      expect(results.map((d) => d.key?.symbol).toList(), ['TCS']);
    });

    test('falls back to holdings when market returns null', () async {
      final results = await searchSymbolsHoldingsFirst(
        query: 'tc',
        holdings: const [
          (symbol: 'TCS', name: 'Tata Consultancy'),
        ],
        marketSearch: (q) async => null,
        limit: 8,
      );

      expect(results.single.key?.symbol, 'TCS');
    });
  });

  group('searchSectorsHoldingsFirst', () {
    test('prefers holdings sectors then catalog', () async {
      final results = await searchSectorsHoldingsFirst(
        query: 'fin',
        holdingsSectors: const ['Financial Services', 'Energy'],
        marketCatalog: const [
          'Financials',
          'Financial Services',
          'Information Technology',
        ],
        limit: 8,
      );

      expect(
        results.map((d) => d.key?.symbol).toList(),
        ['Financial Services', 'Financials'],
      );
    });
  });

  group('labelToSecurityDocument', () {
    test('maps symbol and company name', () {
      final doc = labelToSecurityDocument('TCS', companyName: 'Tata');
      expect(doc, isA<market.SecurityDocument>());
      expect(doc.key?.symbol, 'TCS');
      expect(doc.metadata?.companyName, 'Tata');
    });
  });
}
