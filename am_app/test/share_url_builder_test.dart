import 'package:flutter_test/flutter_test.dart';

import 'package:am_app/core/router/app_routes.dart';
import 'package:am_app/core/router/share_url_builder.dart';
import 'package:am_auth_ui/core/utils/auth_redirect.dart';

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

    group('existing login regressions', () {
      test('plain /login with no redirect goes to dashboard', () {
        expect(
          AuthRedirect.postLoginLocation(Uri.parse('/login')),
          '/app/dashboard',
        );
      });

      test('plain /login ignores unrelated query when redirect missing', () {
        expect(
          AuthRedirect.postLoginLocation(
            Uri.parse('/login?utm_source=email&foo=bar'),
          ),
          '/app/dashboard',
        );
      });

      test('empty redirect goes to dashboard', () {
        expect(
          AuthRedirect.postLoginLocation(Uri.parse('/login?redirect=')),
          '/app/dashboard',
        );
      });

      test('classic encoded redirect to portfolio is unchanged', () {
        expect(
          AuthRedirect.postLoginLocation(
            Uri.parse('/login?redirect=%2Fapp%2Fportfolio%2Fp1%2Fholdings'),
          ),
          '/app/portfolio/p1/holdings',
        );
      });

      test('classic plain redirect to dashboard is unchanged', () {
        expect(
          AuthRedirect.postLoginLocation(
            Uri.parse('/login?redirect=/app/dashboard'),
          ),
          '/app/dashboard',
        );
      });

      test('classic nested redirect query still lands on app path', () {
        expect(
          AuthRedirect.postLoginLocation(
            Uri.parse(
              '/login?redirect=/app/profile%3Fhighlight%3Dsubscription',
            ),
          ),
          '/app/profile?highlight=subscription',
        );
      });

      test('rejects non-app and external redirects', () {
        expect(
          AuthRedirect.postLoginLocation(
            Uri.parse('/login?redirect=/login'),
          ),
          '/app/dashboard',
        );
        expect(
          AuthRedirect.postLoginLocation(
            Uri.parse('/login?redirect=https://evil.com'),
          ),
          '/app/dashboard',
        );
        expect(
          AuthRedirect.postLoginLocation(
            Uri.parse('/login?redirect=https://evil.com/phishing'),
          ),
          '/app/dashboard',
        );
      });

      test('absolute same-origin app URL still sanitizes to path', () {
        expect(
          AuthRedirect.sanitize(
            'https://am.asrax.in/app/market/all-indices?x=1',
          ),
          '/app/market/all-indices?x=1',
        );
      });

      test('auth bounce for path-only app URL matches classic shape', () {
        final login = AuthRedirect.loginLocationFromAppUri(
          Uri.parse('/app/portfolio/p1/holdings'),
        );
        final uri = Uri.parse(login);
        expect(uri.path, '/login');
        expect(uri.queryParameters['redirect'], '/app/portfolio/p1/holdings');
        expect(uri.queryParameters.length, 1);
        expect(
          AuthRedirect.postLoginLocation(uri),
          '/app/portfolio/p1/holdings',
        );
      });

      test('recoverLoginLocation for unknown 404 is bare login', () {
        expect(
          AuthRedirect.recoverLoginLocation(Uri.parse('/no-such-page')),
          '/login',
        );
      });

      test('external return without redirect goes to profile not dashboard', () {
        final target = AuthRedirect.postLoginLocation(
          Uri.parse(
            '/login?return_to=http%3A%2F%2F127.0.0.1%3A18787%2Fcallback&state=s1',
          ),
        );
        final uri = Uri.parse(target);
        expect(uri.path, '/app/profile');
        expect(uri.path, isNot(AuthRedirect.productHomePath));
        expect(uri.queryParameters['return_to'], 'http://127.0.0.1:18787/callback');
        expect(uri.queryParameters['state'], 's1');
      });

      test('ide_return without redirect goes to profile not dashboard', () {
        final target = AuthRedirect.postLoginLocation(
          Uri.parse(
            '/login?ide_return=http%3A%2F%2F127.0.0.1%3A18787%2Fauth-callback&state=s1',
          ),
        );
        expect(Uri.parse(target).path, '/app/profile');
        expect(target.contains('/app/dashboard'), isFalse);
      });

      test('external return does not keep mistaken dashboard redirect', () {
        final target = AuthRedirect.postLoginLocation(
          Uri.parse(
            '/login?redirect=%2Fapp%2Fdashboard&return_to=http%3A%2F%2F127.0.0.1%3A9%2Fcb',
          ),
        );
        expect(Uri.parse(target).path, '/app/profile');
      });
    });

    test('sanitizeRedirect unpacks nested and percent-encoded query', () {
      expect(
        ShareUrlBuilder.sanitizeRedirect(
          '/app/profile?highlight=subscription',
        ),
        '/app/profile?highlight=subscription',
      );
      expect(
        ShareUrlBuilder.sanitizeRedirect(
          '/app/profile%3Fhighlight%3Dsubscription',
        ),
        '/app/profile?highlight=subscription',
      );
      expect(
        ShareUrlBuilder.sanitizeRedirect(
          '/app/profile?return_to=http%3A%2F%2F127.0.0.1%3A18787%2Fcallback',
        ),
        '/app/profile?return_to=http%3A%2F%2F127.0.0.1%3A18787%2Fcallback',
      );
    });

    test('loginLocation keeps companion query as siblings', () {
      final login = AuthRedirect.loginLocation(
        appPath: '/app/profile',
        companionQuery: {
          'state': 'abc',
          'return_to': 'http://127.0.0.1:18787/callback',
        },
      );
      final uri = Uri.parse(login);
      expect(uri.path, '/login');
      expect(uri.queryParameters['redirect'], '/app/profile');
      expect(uri.queryParameters['state'], 'abc');
      expect(
        uri.queryParameters['return_to'],
        'http://127.0.0.1:18787/callback',
      );
      expect(uri.queryParameters['redirect']!.contains('?'), isFalse);
    });

    test('loginLocationFromAppUri does not nest path query into redirect', () {
      final login = AuthRedirect.loginLocationFromAppUri(
        Uri.parse('/app/profile?highlight=subscription&state=s1'),
      );
      final uri = Uri.parse(login);
      expect(uri.queryParameters['redirect'], '/app/profile');
      expect(uri.queryParameters['highlight'], 'subscription');
      expect(uri.queryParameters['state'], 's1');
    });

    test('postLoginLocation merges sibling and nested redirect query', () {
      expect(
        AuthRedirect.postLoginLocation(
          Uri.parse('/login?redirect=%2Fapp%2Fprofile&state=s1'),
        ),
        '/app/profile?state=s1',
      );
      expect(
        AuthRedirect.postLoginLocation(
          Uri.parse(
            '/login?redirect=/app/profile%3Fhighlight%3Dsubscription&state=s1',
          ),
        ),
        '/app/profile?highlight=subscription&state=s1',
      );
    });

    test('recoverLoginLocation rebuilds login from encoded path', () {
      final recovered = AuthRedirect.recoverLoginLocation(
        Uri.parse('/app/profile%3Fhighlight%3Dsubscription'),
      );
      final uri = Uri.parse(recovered);
      expect(uri.path, '/login');
      expect(uri.queryParameters['redirect'], '/app/profile');
      expect(uri.queryParameters['highlight'], 'subscription');
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
