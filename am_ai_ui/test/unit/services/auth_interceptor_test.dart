import 'package:am_auth_ui/core/network/auth_interceptor.dart';
import 'package:am_auth_ui/core/services/secure_storage_service.dart';
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

void main() {
  group('AuthInterceptor', () {
    test('copies unmodifiable headers before writing Authorization', () async {
      final dio = Dio();
      dio.interceptors.add(AuthInterceptor(_FakeStorage('tok-123')));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.headers['Authorization'], 'Bearer tok-123');
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
      dio.interceptors.add(AuthInterceptor(_ThrowingStorage()));

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
