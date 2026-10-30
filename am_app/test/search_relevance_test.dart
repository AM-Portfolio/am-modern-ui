import 'package:am_app/features/search/search_context.dart';
import 'package:am_app/features/search/search_relevance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int cmp({
    required String query,
    required SearchContext context,
    required String aTitle,
    required String bTitle,
    String aCategory = 'Market',
    String bCategory = 'Market',
    String aSubtitle = '',
    String bSubtitle = '',
    int aIndex = 0,
    int bIndex = 1,
  }) {
    return SearchRelevance.compare(
      context: context,
      query: query,
      aCategory: aCategory,
      aTitle: aTitle,
      aSubtitle: aSubtitle,
      aIndex: aIndex,
      bCategory: bCategory,
      bTitle: bTitle,
      bSubtitle: bSubtitle,
      bIndex: bIndex,
    );
  }

  test('exact PNB ranks above digit bond tickers', () {
    expect(
      cmp(
        query: 'pnb',
        context: SearchContext.equityInsider,
        aTitle: 'PNB',
        bTitle: '810PNB24',
      ),
      lessThan(0),
    );
    expect(
      cmp(
        query: 'pnb',
        context: SearchContext.market,
        aTitle: 'PNB',
        bTitle: 'PNBGILTS',
      ),
      lessThan(0),
    );
  });

  test('exact NIFTY ranks above dated contracts in F&O', () {
    expect(
      cmp(
        query: 'nifty',
        context: SearchContext.fo,
        aTitle: 'NIFTY',
        bTitle: 'NIFTY24APR',
      ),
      lessThan(0),
    );
  });

  test('Portfolio category beats Market for the same symbol match', () {
    expect(
      cmp(
        query: 'irfc',
        context: SearchContext.portfolio,
        aTitle: 'IRFC',
        aCategory: 'Portfolio',
        aSubtitle: 'Holding · INDIAN RAILWAY',
        bTitle: '687IRFC32',
        bCategory: 'Market',
      ),
      lessThan(0),
    );
  });
}
