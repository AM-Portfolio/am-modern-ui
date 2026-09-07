import 'package:am_auth_ui/features/authentication/data/datasources/identity_auth_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IdentityAuthRemoteDataSource.logout', () {
    test('posts refresh_token in body when provided', () async {
      Map<String, dynamic>? capturedBody;

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedBody = options.data as Map<String, dynamic>?;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 204,
              ),
            );
          },
        ),
      );

      final dataSource = IdentityAuthRemoteDataSource(dio);
      await dataSource.logout(refreshToken: 'refresh-abc');

      expect(capturedBody, isNotNull);
      expect(capturedBody!['refresh_token'], 'refresh-abc');
    });

    test('omits body when refresh token is absent', () async {
      dynamic capturedBody;

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedBody = options.data;
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 204,
              ),
            );
          },
        ),
      );

      final dataSource = IdentityAuthRemoteDataSource(dio);
      await dataSource.logout();

      expect(capturedBody, isNull);
    });
  });

  group('IdentityAuthRemoteDataSource.refreshToken', () {
    test('parses expires_in and optional rotated refresh', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'access_token': 'access-new',
                  'refresh_token': 'refresh-new',
                  'expires_in': 300,
                },
              ),
            );
          },
        ),
      );

      final dataSource = IdentityAuthRemoteDataSource(dio);
      final before = DateTime.now();
      final tokens = await dataSource.refreshToken('refresh-old');

      expect(tokens.accessToken, 'access-new');
      expect(tokens.refreshToken, 'refresh-new');
      expect(
        tokens.expiresAt.isAfter(before.add(const Duration(seconds: 290))),
        isTrue,
      );
    });
  });
}
