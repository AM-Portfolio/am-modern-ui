import 'package:am_library/core/auth/user_context.dart';

import '../services/secure_storage_service.dart';
import '../../features/authentication/data/models/auth_tokens_model.dart';

typedef TokenRefreshApi = Future<AuthTokensModel> Function(String refreshToken);

class TokenRefreshService {
  TokenRefreshService({
    required SecureStorageService storageService,
    required TokenRefreshApi refreshApi,
  })  : _storageService = storageService,
        _refreshApi = refreshApi;

  final SecureStorageService _storageService;
  final TokenRefreshApi _refreshApi;

  Future<bool>? _inFlight;

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
