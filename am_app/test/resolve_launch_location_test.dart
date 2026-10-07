import 'package:am_common/am_common.dart' as common;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await common.SessionPersistenceService.instance.clear('test-user');
    });

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

    test('root and unknown paths open login (not dashboard spinner)', () {
      expect(
        resolveLaunchLocation(launchUri: Uri.parse('https://am.asrax.in/')),
        AppRoutes.login,
      );
      expect(
        resolveLaunchLocation(launchUri: Uri.parse('http://localhost:9000/')),
        AppRoutes.login,
      );
      expect(
        resolveLaunchLocation(launchUri: Uri.parse('https://am.asrax.in/unknown')),
        AppRoutes.login,
      );
    });

    test('null launchUri defaults to dashboard on native (no login flash)', () {
      expect(resolveLaunchLocation(launchUri: null), AppRoutes.dashboard);
    });

    test('null launchUri uses cached session nav path when available', () async {
      await common.SessionPersistenceService.instance.saveNow(
        'test-user',
        common.AppSessionState.initial(globalNav: 'Market'),
      );
      expect(
        resolveLaunchLocation(launchUri: null),
        AppRoutes.navTitleToDefaultPath['Market'],
      );
    });

    test('null launchUri restores portfolio path from cached session', () async {
      await common.SessionPersistenceService.instance.saveNow(
        'test-user',
        common.AppSessionState(
          savedAt: DateTime.now(),
          globalNav: 'Portfolio',
          portfolioId: 'pf-123',
          portfolioTabIndex: 1,
        ),
      );
      expect(
        resolveLaunchLocation(launchUri: null),
        AppRoutes.portfolioPath('pf-123', 'holdings'),
      );
    });
  });
}
