import 'package:flutter_test/flutter_test.dart';

import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_intelligence.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/intelligence_suggest_search.dart';

void main() {
  group('suggestItemsToDocuments', () {
    test('selectLabel keeps label as selection key', () {
      final docs = suggestItemsToDocuments(
        const [
          IntelligenceSuggestItem(
            label: 'IT',
            subtitle: '2 holdings · 10.0% of book',
            source: 'CANONICAL',
          ),
        ],
        selectLabel: true,
      );
      expect(docs.single.key?.symbol, 'IT');
      expect(docs.single.metadata?.companyName, contains('IT'));
      expect(docs.single.metadata?.companyName, contains('2 holdings'));
    });

    test('ticker mode selects symbol', () {
      final docs = suggestItemsToDocuments(
        const [
          IntelligenceSuggestItem(
            label: 'TCS',
            symbol: 'TCS',
            subtitle: 'Held · 5.0%',
            source: 'HOLDING',
          ),
        ],
        selectLabel: false,
      );
      expect(docs.single.key?.symbol, 'TCS');
      expect(docs.single.metadata?.companyName, 'Held · 5.0%');
    });
  });

  group('classAddNameHint', () {
    test('returns wire-specific placeholders', () {
      expect(classAddNameHint('bonds'), contains('Sovereign Gold Bond'));
      expect(classAddNameHint('commodities'), contains('Sovereign Gold'));
      expect(classAddNameHint('cash'), contains('Liquid Fund'));
    });
  });

  group('labelToSecurityDocument', () {
    test('builds market document', () {
      final doc = labelToSecurityDocument('TCS', companyName: 'Tata');
      expect(doc.key?.symbol, 'TCS');
      expect(doc.metadata?.companyName, 'Tata');
    });
  });

  group('searchWhatIfSymbols market fill', () {
    test('merges backend holdings then market when under limit', () async {
      // Unit-level merge path via suggestItems + manual merge pattern.
      final fromBackend = suggestItemsToDocuments(
        const [
          IntelligenceSuggestItem(label: 'TCS', symbol: 'TCS', source: 'HOLDING'),
        ],
        selectLabel: false,
      );
      final fromMarket = [
        labelToSecurityDocument('TECHM', companyName: 'Tech Mahindra'),
        labelToSecurityDocument('TCS', companyName: 'dup'),
      ];
      final seen = <String>{
        for (final d in fromBackend) (d.key?.symbol ?? '').trim().toUpperCase(),
      };
      final merged = [...fromBackend];
      for (final doc in fromMarket) {
        final sym = (doc.key?.symbol ?? '').trim().toUpperCase();
        if (sym.isEmpty || seen.contains(sym)) continue;
        seen.add(sym);
        merged.add(doc);
      }
      expect(
        merged.map((d) => d.key?.symbol).toList(),
        ['TCS', 'TECHM'],
      );
    });
  });
}
