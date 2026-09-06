import 'package:am_auth_ui/core/services/app_lock_service.dart';
import 'package:am_auth_ui/core/services/token_refresh_service.dart';
import 'package:am_auth_ui/features/authentication/data/models/auth_tokens_model.dart';
import 'package:am_library/core/services/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_jwt.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SecureStorageService.evictCache();
  });

  group('AppLockService', () {
    test('requiresUnlock is true when never unlocked', () async {
      final service = AppLockService(
        storageService: SecureStorageService(),
        authenticate: () async => true,
      );

      expect(await service.requiresUnlock(), isTrue);
    });

    test('requiresUnlock is false when unlocked within 24h', () async {
      final storage = SecureStorageService();
      await storage.saveLastAppUnlockAt(
        DateTime(2026, 9, 3, 12),
      );

      final service = AppLockService(
        storageService: storage,
        clock: () => DateTime(2026, 9, 3, 18),
        authenticate: () async => true,
      );

      expect(await service.requiresUnlock(), isFalse);
    });

    test('requiresUnlock is true after 24h', () async {
      final storage = SecureStorageService();
      await storage.saveLastAppUnlockAt(
        DateTime(2026, 9, 1, 12),
      );

      final service = AppLockService(
        storageService: storage,
        clock: () => DateTime(2026, 9, 3, 12, 1),
        authenticate: () async => true,
      );

      expect(await service.requiresUnlock(), isTrue);
    });

    test('unlock refreshes expired access token', () async {
      final storage = SecureStorageService();
      await storage.saveRefreshToken('refresh-old');
      await storage.saveUserId('user-1');
      await storage.saveUserEmail('user@example.com');
      await storage.saveAccessToken('expired');
      await storage.saveTokenExpiry(DateTime(2020));

      var refreshCalls = 0;
      final refreshService = TokenRefreshService(
        storageService: storage,
        refreshApi: (_) async {
          refreshCalls++;
          return AuthTokensModel(
            accessToken: testJwt(),
            refreshToken: 'refresh-new',
            expiresAt: DateTime.now().add(const Duration(minutes: 5)),
          );
        },
      );

      final service = AppLockService(
        storageService: storage,
        tokenRefreshService: refreshService,
        clock: () => DateTime(2026, 9, 3, 12),
        authenticate: () async => true,
      );

      expect(await service.unlock(), isTrue);
      expect(refreshCalls, 1);
      expect(await storage.getLastAppUnlockAt(), isNotNull);
    });
  });
}
