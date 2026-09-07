import 'dart:async';

import 'package:am_auth_ui/core/services/token_refresh_service.dart';
import 'package:am_auth_ui/features/authentication/data/models/auth_tokens_model.dart';
import 'package:am_library/core/auth/user_context.dart';
import 'package:am_library/core/services/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_jwt.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SecureStorageService.evictCache();
    UserContext.overrideForTesting(
      UserContext.instance,
    );
  });

  group('TokenRefreshService', () {
    test('returns false when refresh token is missing', () async {
      final service = TokenRefreshService(
        storageService: SecureStorageService(),
        refreshApi: (_) async => throw StateError('should not refresh'),
      );

      expect(await service.refreshAccessToken(), isFalse);
    });

    test('persists tokens and returns true on success', () async {
      final storage = SecureStorageService();
      await storage.saveRefreshToken('refresh-old');
      await storage.saveUserId('user-1');
      await storage.saveUserEmail('user@example.com');

      final accessToken = testJwt();
      final service = TokenRefreshService(
        storageService: storage,
        refreshApi: (_) async => AuthTokensModel(
          accessToken: accessToken,
          refreshToken: 'refresh-new',
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        ),
      );

      expect(await service.refreshAccessToken(), isTrue);
      expect(await storage.getAccessToken(), accessToken);
      expect(await storage.getRefreshToken(), 'refresh-new');
      expect(UserContext.instance.cachedUserId, 'user-1');
    });

    test('returns false when refresh API fails', () async {
      final storage = SecureStorageService();
      await storage.saveRefreshToken('refresh-old');

      final service = TokenRefreshService(
        storageService: storage,
        refreshApi: (_) async => throw Exception('refresh failed'),
      );

      expect(await service.refreshAccessToken(), isFalse);
      expect(await storage.getAccessToken(), isNull);
    });

    test('concurrent refresh calls share one in-flight operation', () async {
      final storage = SecureStorageService();
      await storage.saveRefreshToken('refresh-old');

      var refreshCallCount = 0;
      final gate = Completer<void>();

      final service = TokenRefreshService(
        storageService: storage,
        refreshApi: (_) async {
          refreshCallCount++;
          await gate.future;
          return AuthTokensModel(
            accessToken: testJwt(),
            refreshToken: 'refresh-new',
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
          );
        },
      );

      final first = service.refreshAccessToken();
      final second = service.refreshAccessToken();

      await Future<void>.delayed(Duration.zero);
      expect(refreshCallCount, 1);

      gate.complete();
      final results = await Future.wait([first, second]);

      expect(results, everyElement(isTrue));
      expect(refreshCallCount, 1);
    });
  });
}
