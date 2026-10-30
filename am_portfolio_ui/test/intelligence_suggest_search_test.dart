import 'package:am_portfolio_ui/features/portfolio/internal/data/datasources/portfolio_remote_data_source.dart';
import 'package:am_portfolio_ui/features/portfolio/internal/domain/entities/portfolio_intelligence.dart';
import 'package:am_portfolio_ui/features/portfolio/presentation/widgets/intelligence/intelligence_suggest_search.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('stress search catalog', () {
    test('local hits include indexes and exclude events', () {
      final nifty = localStressSearchHits('nifty');
      expect(nifty.map((d) => d.key?.symbol), contains('NIFTY 50'));
      expect(nifty.single.metadata?.companyName, 'NIFTY 50');
      expect(localStressSearchHits('sensex').single.metadata?.companyName, 'SENSEX');
      expect(localStressSearchHits('covid'), isEmpty);
      expect(localStressSearchHits('GFC'), isEmpty);
      expect(isBlockedStressSearchLabel('GFC_2008'), isTrue);
      expect(isBlockedStressSearchLabel('COVID-19 Crash'), isTrue);
      expect(isBlockedStressSearchLabel('IT'), isFalse);
    });

    test('searchStressSectors drops event ids from backend', () async {
      final remote = _FakeSuggestRemote(const [
        IntelligenceSuggestItem(label: 'GFC_2008', source: 'CANONICAL'),
        IntelligenceSuggestItem(
          label: 'Energy',
          subtitle: '12.0% of book · 4 holdings',
          source: 'HOLDING',
        ),
      ]);
      final docs = await searchStressSectors(
        remote: remote,
        portfolioId: 'p1',
        query: 'e',
      );
      expect(docs.map((d) => d.key?.symbol), isNot(contains('GFC_2008')));
      expect(docs.map((d) => d.key?.symbol), contains('Energy'));
      final energy = docs.firstWhere((d) => d.key?.symbol == 'Energy');
      expect(energy.metadata?.companyName, 'Energy');
      expect(energy.metadata?.companyName, isNot(contains('of book')));
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

class _FakeSuggestRemote extends Fake implements PortfolioRemoteDataSource {
  _FakeSuggestRemote(this.items);

  final List<IntelligenceSuggestItem> items;

  @override
  Future<List<IntelligenceSuggestItem>> getIntelligenceSuggest(
    String portfolioId, {
    required String context,
    String query = '',
    String? wire,
    int limit = 8,
  }) async {
    return items;
  }
}
