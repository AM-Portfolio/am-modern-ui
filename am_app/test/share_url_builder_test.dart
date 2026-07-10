import 'package:flutter_test/flutter_test.dart';

import 'package:am_app/core/router/app_routes.dart';
import 'package:am_app/core/router/share_url_builder.dart';

void main() {
  group('ShareUrlBuilder', () {
    test('builds portfolio path with id and tab', () {
      expect(
        ShareUrlBuilder.portfolio('abc-123', 'holdings'),
        '/app/portfolio/abc-123/holdings',
      );
    });

    test('builds trade path with id and tab', () {
      expect(
        ShareUrlBuilder.trade('abc-123', 'journal'),
        '/app/trade/abc-123/journal',
      );
    });

    test('parses portfolio id from 3-segment path', () {
      expect(
        ShareUrlBuilder.portfolioIdFromLocation(
          '/app/portfolio/p1/holdings',
        ),
        'p1',
      );
    });

    test('parses portfolio tab from 3-segment path', () {
      expect(
        ShareUrlBuilder.portfolioTabFromLocation('/app/portfolio/p1/heatmap'),
        'heatmap',
      );
    });

    test('parses legacy 2-segment portfolio tab path', () {
      expect(
        ShareUrlBuilder.portfolioTabFromLocation('/app/portfolio/overview'),
        'overview',
      );
      expect(
        ShareUrlBuilder.portfolioIdFromLocation('/app/portfolio/overview'),
        isNull,
      );
    });

    test('trade discovery is not a deep trade link', () {
      expect(ShareUrlBuilder.isDeepTradeLink(AppRoutes.tradeDiscovery), isFalse);
      expect(
        ShareUrlBuilder.tradeTabFromLocation(AppRoutes.tradeDiscovery),
        'portfolios',
      );
    });

    test('detects explicit deep links', () {
      expect(
        ShareUrlBuilder.isExplicitDeepLink('/app/portfolio/p1/holdings'),
        isTrue,
      );
      expect(
        ShareUrlBuilder.isExplicitDeepLink('/app/trade/p1/journal'),
        isTrue,
      );
      expect(
        ShareUrlBuilder.isExplicitDeepLink('/app/portfolio/overview'),
        isFalse,
      );
    });

    test('sanitizeRedirect accepts app paths only', () {
      expect(
        ShareUrlBuilder.sanitizeRedirect('/app/portfolio/p1/holdings'),
        '/app/portfolio/p1/holdings',
      );
      expect(
        ShareUrlBuilder.sanitizeRedirect(
          'https://am.asrax.in/app/market/all-indices',
        ),
        '/app/market/all-indices',
      );
      expect(ShareUrlBuilder.sanitizeRedirect('https://evil.com'), isNull);
      expect(ShareUrlBuilder.sanitizeRedirect(null), isNull);
    });

    test('isReloadableAppRoute detects non-dashboard app paths', () {
      expect(
        ShareUrlBuilder.isReloadableAppRoute('/app/market/all-indices'),
        isTrue,
      );
      expect(
        ShareUrlBuilder.isReloadableAppRoute('/app/portfolio/overview'),
        isTrue,
      );
      expect(ShareUrlBuilder.isReloadableAppRoute('/app/dashboard'), isFalse);
    });

    test('tab slug helpers', () {
      expect(AppRoutes.isPortfolioTab('holdings'), isTrue);
      expect(AppRoutes.isPortfolioTab('not-a-tab'), isFalse);
      expect(AppRoutes.isTradeTab('journal'), isTrue);
    });
  });
}
