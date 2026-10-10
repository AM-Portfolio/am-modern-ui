import 'package:flutter_test/flutter_test.dart';

import 'package:am_app/features/search/adapters/basket_catalog_search_adapter.dart';

void main() {
  group('BasketCatalogSearchAdapter', () {
    late BasketCatalogSearchAdapter adapter;

    setUp(() {
      adapter = BasketCatalogSearchAdapter(
        catalogLoader: () async => const [
          BasketThemeHit(
            id: 'gold',
            label: 'Gold',
            query: 'GOLDBEES',
            featured: true,
          ),
          BasketThemeHit(
            id: 'it',
            label: 'IT',
            query: 'ITBEES',
            featured: true,
          ),
          BasketThemeHit(
            id: 'bank',
            label: 'Bank',
            query: 'BANKBEES',
            featured: false,
          ),
        ],
      );
    });

    test('matches Gold by label', () async {
      final hits = await adapter.search('Gold');
      expect(hits, hasLength(1));
      expect(hits.first.label, 'Gold');
      expect(hits.first.query, 'GOLDBEES');
    });

    test('matches gold case-insensitively and by ETF query', () async {
      expect((await adapter.search('gold')).single.query, 'GOLDBEES');
      expect((await adapter.search('GOLDBEES')).single.label, 'Gold');
    });

    test('matches IT theme', () async {
      final hits = await adapter.search('IT');
      expect(hits.any((h) => h.label == 'IT'), isTrue);
    });

    test('returns empty for unrelated query', () async {
      expect(await adapter.search('zzzz-not-a-theme'), isEmpty);
    });

    test('featuredCached prefers featured themes', () async {
      await adapter.ensureLoaded();
      final featured = adapter.featuredCached;
      expect(featured.map((t) => t.id), containsAll(['gold', 'it']));
      expect(featured.any((t) => t.id == 'bank'), isFalse);
    });
  });
}
