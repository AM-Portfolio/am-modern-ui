import 'package:dio/dio.dart';

import '../../di/auth_providers.dart';
import 'same_origin_navigation.dart';

const _qaApiBase = String.fromEnvironment(
  'QA_API_BASE',
  defaultValue: '',
);

bool _looksLikeJwt(String? token) {
  if (token == null || token.isEmpty) return false;
  if (token == 'bff_cookie_session' || token.startsWith('web-access-')) {
    return false;
  }
  return token.split('.').length >= 3;
}

/// After Modern UI login, mint a one-time handoff (when possible) and open QA.
Future<void> handoffToQaPortalAfterLogin(String target) async {
  String? token;
  try {
    token = await AuthProviders.secureStorageService.getAccessToken(
      checkExpiry: false,
    );
  } catch (_) {}

  String? handoff;
  final apiBase = _qaApiBase.trim().replaceAll(RegExp(r'/$'), '');
  if (apiBase.isNotEmpty && _looksLikeJwt(token)) {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      final resp = await dio.post<Map<String, dynamic>>(
        '$apiBase/api/v1/auth/central-handoff-mint',
        data: {'access_token': token},
      );
      final code = resp.data?['handoff'];
      if (code is String && code.isNotEmpty) {
        handoff = code;
      }
    } catch (_) {
      // Fall back to passing the JWT directly when mint is unavailable.
    }
  }

  navigateToSameOrigin(
    target,
    accessToken: handoff == null ? token : null,
    handoffCode: handoff,
  );
}
