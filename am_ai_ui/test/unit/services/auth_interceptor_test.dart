import 'package:am_auth_ui/core/network/auth_interceptor.dart';
import 'package:am_auth_ui/core/services/secure_storage_service.dart';
import 'package:am_auth_ui/core/services/token_refresh_service.dart';
import 'package:am_auth_ui/features/authentication/data/models/auth_tokens_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStorage extends Fake implements SecureStorageService {
  _FakeStorage(this.token);
  final String? token;

  @override
  Future<String?> getAccessToken({bool checkExpiry = true}) async => token;
}

class _ThrowingStorage extends Fake implements SecureStorageService {
  @override
  Future<String?> getAccessToken({bool checkExpiry = true}) async {
    throw StateError('storage unavailable');
  }
}

/// Minimal JWT shape so [_shouldAttachBearer] accepts the token.
const _jwt = 'aaa.eyJzdWIiOiJ1MSJ9.sig';

TokenRefreshService _refresh(SecureStorageService storage) {
  return TokenRefreshService(
    storageService: storage,
    refreshApi: (_) async => AuthTokensModel(
      accessToken: _jwt,
      refreshToken: 'r',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    ),
  );
}

void main() {
  group('AuthInterceptor', () {
    test('copies unmodifiable headers before writing Authorization', () async {
      final dio = Dio();
      final storage = _FakeStorage(_jwt);
      dio.interceptors.add(
        AuthInterceptor(
          storage,
          tokenRefreshService: _refresh(storage),
          dio: dio,
        ),
      );
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.headers['Authorization'], 'Bearer $_jwt');
            expect(options.headers['Content-Type'], 'application/json');
            handler.resolve(
              Response(requestOptions: options, statusCode: 200, data: const {}),
            );
          },
        ),
      );

      final response = await dio.fetch(
        RequestOptions(
          path: '/v1/ai/chat',
          headers: Map<String, dynamic>.unmodifiable({
            'Content-Type': 'application/json',
          }),
        ),
      );
      expect(response.statusCode, 200);
    });

    test('rejects instead of hanging when token lookup fails', () async {
      final dio = Dio();
      final storage = _ThrowingStorage();
      dio.interceptors.add(
        AuthInterceptor(
          storage,
          tokenRefreshService: _refresh(storage),
          dio: dio,
        ),
      );

      await expectLater(
        dio.fetch(RequestOptions(path: '/v1/ai/chat')),
        throwsA(
          isA<DioException>().having(
            (e) => e.message,
            'message',
            contains('Auth interceptor failed'),
          ),
        ),
      );
    });
  });
}
