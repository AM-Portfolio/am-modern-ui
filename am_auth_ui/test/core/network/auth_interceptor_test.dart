import 'package:am_auth_ui/core/network/auth_interceptor.dart';

import 'package:am_auth_ui/core/services/secure_storage_service.dart';

import 'package:am_auth_ui/core/services/token_refresh_service.dart';

import 'package:am_auth_ui/features/authentication/data/models/auth_tokens_model.dart';

import 'package:dio/dio.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:flutter_test/flutter_test.dart';



import '../../test_jwt.dart';



class _StubHttpClientAdapter implements HttpClientAdapter {

  _StubHttpClientAdapter(this._respond);



  final ResponseBody Function(int callIndex) _respond;

  var callIndex = 0;



  @override

  void close({bool force = false}) {}



  @override

  Future<ResponseBody> fetch(

    RequestOptions options,

    Stream<List<int>>? requestStream,

    Future<void>? cancelFuture,

  ) async {

    callIndex++;

    return _respond(callIndex);

  }

}



void main() {

  TestWidgetsFlutterBinding.ensureInitialized();



  setUp(() {

    FlutterSecureStorage.setMockInitialValues({});

    SecureStorageService.evictCache();

  });



  group('AuthInterceptor', () {

    test('retries once after 401 when refresh succeeds', () async {

      final storage = SecureStorageService();

      final expiredToken = testJwt(validFor: const Duration(minutes: -5));

      final freshToken = testJwt();

      await storage.saveAccessToken(expiredToken);

      await storage.saveRefreshToken('refresh-token');



      final dio = Dio();

      final refreshService = TokenRefreshService(

        storageService: storage,

        refreshApi: (_) async => AuthTokensModel(

          accessToken: freshToken,

          refreshToken: 'refresh-token',

          expiresAt: DateTime.now().add(const Duration(minutes: 5)),

        ),

      );



      late _StubHttpClientAdapter adapter;

      adapter = _StubHttpClientAdapter((callIndex) {

        if (callIndex == 1) {

          return ResponseBody.fromString(

            '',

            401,

            headers: {

              Headers.contentTypeHeader: [Headers.jsonContentType],

            },

          );

        }



        return ResponseBody.fromString(

          '{"ok":true}',

          200,

          headers: {

            Headers.contentTypeHeader: [Headers.jsonContentType],

          },

        );

      });

      dio.httpClientAdapter = adapter;



      dio.interceptors.add(

        AuthInterceptor(

          storage,

          tokenRefreshService: refreshService,

          dio: dio,

        ),

      );



      final response = await dio.get<dynamic>('https://example.com/api/portfolio');



      expect(response.statusCode, 200);

      expect(adapter.callIndex, 2);

      expect(await storage.getAccessToken(), freshToken);

    });



    test('does not retry refresh endpoint on 401', () async {

      final storage = SecureStorageService();

      await storage.saveAccessToken(testJwt(validFor: const Duration(minutes: -5)));

      await storage.saveRefreshToken('refresh-token');



      var refreshApiCalled = false;

      final dio = Dio();

      dio.httpClientAdapter = _StubHttpClientAdapter(

        (_) => ResponseBody.fromString('', 401),

      );

      dio.interceptors.add(

        AuthInterceptor(

          storage,

          tokenRefreshService: TokenRefreshService(

            storageService: storage,

            refreshApi: (_) async {

              refreshApiCalled = true;

              throw Exception('should not refresh');

            },

          ),

          dio: dio,

        ),

      );



      await expectLater(

        dio.post<dynamic>('https://example.com/identity/auth/refresh'),

        throwsA(isA<DioException>()),

      );



      expect(refreshApiCalled, isFalse);

    });

    test('passes 401 through when retry also returns 401', () async {
      final storage = SecureStorageService();
      await storage.saveAccessToken(testJwt(validFor: const Duration(minutes: -5)));
      await storage.saveRefreshToken('refresh-token');

      var refreshCallCount = 0;
      final dio = Dio();
      dio.httpClientAdapter = _StubHttpClientAdapter(
        (_) => ResponseBody.fromString('', 401),
      );
      dio.interceptors.add(
        AuthInterceptor(
          storage,
          tokenRefreshService: TokenRefreshService(
            storageService: storage,
            refreshApi: (_) async {
              refreshCallCount++;
              return AuthTokensModel(
                accessToken: testJwt(),
                refreshToken: 'refresh-token',
                expiresAt: DateTime.now().add(const Duration(minutes: 5)),
              );
            },
          ),
          dio: dio,
        ),
      );

      await expectLater(
        dio.get<dynamic>('https://example.com/api/portfolio'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
      expect(refreshCallCount, 1);
    });

    test('does not refresh on non-401 errors', () async {
      final storage = SecureStorageService();
      await storage.saveAccessToken(testJwt());
      await storage.saveRefreshToken('refresh-token');

      var refreshApiCalled = false;
      final dio = Dio();
      dio.httpClientAdapter = _StubHttpClientAdapter(
        (_) => ResponseBody.fromString('server error', 500),
      );
      dio.interceptors.add(
        AuthInterceptor(
          storage,
          tokenRefreshService: TokenRefreshService(
            storageService: storage,
            refreshApi: (_) async {
              refreshApiCalled = true;
              throw Exception('should not refresh');
            },
          ),
          dio: dio,
        ),
      );

      await expectLater(
        dio.get<dynamic>('https://example.com/api/portfolio'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
      expect(refreshApiCalled, isFalse);
    });

  });

}


