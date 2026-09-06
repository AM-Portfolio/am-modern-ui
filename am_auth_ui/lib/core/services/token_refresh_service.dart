import 'dart:async';

import 'package:am_design_system/core/config/feature_flags.dart';
import 'package:am_library/core/auth/user_context.dart';

import '../services/secure_storage_service.dart';
import '../../features/authentication/data/models/auth_tokens_model.dart';

typedef TokenRefreshApi = Future<AuthTokensModel> Function(String refreshToken);
typedef ProactiveRefreshTick = Future<void> Function();

class TokenRefreshService {
  TokenRefreshService({
    required SecureStorageService storageService,
    required TokenRefreshApi refreshApi,
    FeatureFlags? featureFlags,
    ProactiveRefreshTick? onProactiveRefresh,
  })  : _storageService = storageService,
        _refreshApi = refreshApi,
        _featureFlags = featureFlags ?? FeatureFlags(),
        _onProactiveRefresh = onProactiveRefresh;

  final SecureStorageService _storageService;
  final TokenRefreshApi _refreshApi;
  final FeatureFlags _featureFlags;
  final ProactiveRefreshTick? _onProactiveRefresh;

  Future<bool>? _inFlight;
  Timer? _proactiveTimer;

  Future<bool> refreshAccessToken() {
    final existing = _inFlight;
    if (existing != null) {
      return existing;
    }

    final operation = _refreshAccessTokenInternal();
    _inFlight = operation;
    return operation.whenComplete(() {
      if (identical(_inFlight, operation)) {
        _inFlight = null;
      }
    });
  }

  Future<bool> _refreshAccessTokenInternal() async {
    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final tokens = await _refreshApi(refreshToken);
      await _persistTokens(tokens);
      await _warmUserContext(tokens.accessToken);
      return true;
    } catch (_) {
      return false;
    }
  }

  void configureProactiveRefresh() {
    _proactiveTimer?.cancel();
    if (!_featureFlags.aggressiveTokenRefresh) return;

    final intervalMinutes = _featureFlags.tokenRefreshIntervalMin;
    _proactiveTimer = Timer.periodic(
      Duration(minutes: intervalMinutes),
      (_) => _runProactiveRefresh(),
    );
  }

  void stopProactiveRefresh() {
    _proactiveTimer?.cancel();
    _proactiveTimer = null;
  }

  Future<void> _runProactiveRefresh() async {
    if (_onProactiveRefresh != null) {
      await _onProactiveRefresh!();
      return;
    }
    final expiry = await _storageService.getTokenExpiry();
    if (expiry == null) return;
    final refreshLead = Duration(minutes: _featureFlags.tokenRefreshIntervalMin);
    if (DateTime.now().isAfter(expiry.subtract(refreshLead))) {
      await refreshAccessToken();
    }
  }

  void dispose() {
    stopProactiveRefresh();
  }

  Future<void> _persistTokens(AuthTokensModel tokens) async {
    await _storageService.saveAccessToken(tokens.accessToken);
    if (tokens.refreshToken != null && tokens.refreshToken!.isNotEmpty) {
      await _storageService.saveRefreshToken(tokens.refreshToken!);
    }
    await _storageService.saveTokenExpiry(tokens.expiresAt);
  }

  Future<void> _warmUserContext(String accessToken) async {
    UserContext.instance.invalidate();
    final userId = await _storageService.getUserId();
    final email = await _storageService.getUserEmail();
    if (userId != null &&
        userId.isNotEmpty &&
        email != null &&
        email.isNotEmpty) {
      UserContext.instance.populate(
        accessToken: accessToken,
        userId: userId,
        email: email,
      );
    }
  }
}
