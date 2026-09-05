import 'package:local_auth/local_auth.dart';

import 'secure_storage_service.dart';
import 'token_refresh_service.dart';

typedef LocalAuthChallenge = Future<bool> Function();

class AppLockService {
  AppLockService({
    required SecureStorageService storageService,
    TokenRefreshService? tokenRefreshService,
    LocalAuthentication? localAuth,
    DateTime Function()? clock,
    LocalAuthChallenge? authenticate,
  })  : _storageService = storageService,
        _tokenRefreshService = tokenRefreshService,
        _localAuth = localAuth ?? LocalAuthentication(),
        _clock = clock ?? DateTime.now,
        _authenticate = authenticate;

  static const Duration lockInterval = Duration(hours: 24);

  final SecureStorageService _storageService;
  final TokenRefreshService? _tokenRefreshService;
  final LocalAuthentication _localAuth;
  final DateTime Function() _clock;
  final LocalAuthChallenge? _authenticate;

  Future<bool> requiresUnlock() async {
    final lastUnlock = await _storageService.getLastAppUnlockAt();
    if (lastUnlock == null) return true;
    return _clock().difference(lastUnlock) >= lockInterval;
  }

  Future<bool> unlock() async {
    final authenticated = await _performBiometric();
    if (!authenticated) return false;

    await _storageService.saveLastAppUnlockAt(_clock());

    if (_tokenRefreshService != null &&
        await _storageService.isTokenExpired()) {
      final refreshed = await _tokenRefreshService.refreshAccessToken();
      if (!refreshed) return false;
    }

    return true;
  }

  Future<bool> _performBiometric() async {
    if (_authenticate != null) {
      return _authenticate();
    }

    final canCheck = await _localAuth.canCheckBiometrics;
    final isSupported = await _localAuth.isDeviceSupported();
    if (!canCheck && !isSupported) {
      return true;
    }

    return _localAuth.authenticate(
      localizedReason: 'Unlock AM to continue',
      options: const AuthenticationOptions(
        stickyAuth: true,
        biometricOnly: false,
      ),
    );
  }
}
