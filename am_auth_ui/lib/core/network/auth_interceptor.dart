import 'package:dio/dio.dart';
import '../constants/auth_endpoints.dart';
import '../services/secure_storage_service.dart';

/// Interceptor to add authentication token to requests
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._storageService);
  final SecureStorageService _storageService;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storageService.getAccessToken();

    // Add token to header if available
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 &&
        err.requestOptions.extra['authRefreshRetried'] != true) {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        try {
          final refreshResponse = await Dio().post<Map<String, dynamic>>(
            AuthEndpoints.identityRefreshToken,
            data: {'refresh_token': refreshToken},
          );
          final data = refreshResponse.data!;
          final accessToken = data['access_token'] as String;
          await _storageService.saveAccessToken(accessToken);
          final nextRefreshToken = data['refresh_token'] as String?;
          if (nextRefreshToken != null && nextRefreshToken.isNotEmpty) {
            await _storageService.saveRefreshToken(nextRefreshToken);
          }

          final options = err.requestOptions;
          options.extra['authRefreshRetried'] = true;
          options.headers['Authorization'] = 'Bearer $accessToken';
          final response = await Dio().fetch<dynamic>(options);
          return handler.resolve(response);
        } catch (_) {
          // Preserve the original 401 if refresh or replay fails.
        }
      }
    }

    return handler.next(err);
  }
}
