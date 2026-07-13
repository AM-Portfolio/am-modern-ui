import 'package:flutter_test/flutter_test.dart';

import 'package:am_app/core/router/app_routes.dart';
import 'package:am_app/core/router/launch_location.dart';

void main() {
  group('AppRoutes public auth helpers', () {
    test('normalizePath strips trailing slash', () {
      expect(AppRoutes.normalizePath('/reset-password/'), '/reset-password');
      expect(AppRoutes.normalizePath('/'), '/');
      expect(AppRoutes.normalizePath('/login'), '/login');
    });

    test('isPublicAuthRoute includes reset and verify', () {
      expect(AppRoutes.isPublicAuthRoute('/reset-password'), isTrue);
      expect(AppRoutes.isPublicAuthRoute('/reset-password/'), isTrue);
      expect(AppRoutes.isPublicAuthRoute('/verify-email'), isTrue);
      expect(AppRoutes.isPublicAuthRoute('/forgot-password'), isTrue);
      expect(AppRoutes.isPublicAuthRoute('/app/dashboard'), isFalse);
    });
  });

  group('resolveLaunchLocation', () {
    test('keeps reset-password with short code query', () {
      expect(
        resolveLaunchLocation(
          launchUri: Uri.parse('https://am.asrax.in/reset-password?c=3vxnvHhX0IP3'),
        ),
        '/reset-password?c=3vxnvHhX0IP3',
      );
    });

    test('keeps reset-password with token query', () {
      expect(
        resolveLaunchLocation(
          launchUri: Uri.parse(
            'https://am.asrax.in/reset-password?token=long.hmac.token',
          ),
        ),
        '/reset-password?token=long.hmac.token',
      );
    });

    test('keeps reset-password with trailing slash', () {
      expect(
        resolveLaunchLocation(
          launchUri: Uri.parse('https://am.asrax.in/reset-password/?c=abc'),
        ),
        '/reset-password?c=abc',
      );
    });

    test('keeps verify-email deep link', () {
      expect(
        resolveLaunchLocation(
          launchUri: Uri.parse('https://am.asrax.in/verify-email?c=CwgH9qkDWi9V'),
        ),
        '/verify-email?c=CwgH9qkDWi9V',
      );
    });

    test('keeps authenticated app deep link', () {
      expect(
        resolveLaunchLocation(
          launchUri: Uri.parse('https://am.asrax.in/app/market/all-indices'),
        ),
        '/app/market/all-indices',
      );
    });

    test('falls back to dashboard for unknown or root paths', () {
      expect(
        resolveLaunchLocation(launchUri: Uri.parse('https://am.asrax.in/')),
        AppRoutes.dashboard,
      );
      expect(
        resolveLaunchLocation(launchUri: Uri.parse('https://am.asrax.in/unknown')),
        AppRoutes.dashboard,
      );
    });
  });
}
