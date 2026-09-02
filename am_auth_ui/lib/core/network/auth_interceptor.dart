import 'package:dio/dio.dart';

import '../services/secure_storage_service.dart';
import '../services/token_refresh_service.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(
    this._storageService, {
    required TokenRefreshService tokenRefreshService,
    required Dio dio,
  })  : _tokenRefreshService = tokenRefreshService,
        _dio = dio;

  final SecureStorageService _storageService;
  final TokenRefreshService _tokenRefreshService;
  final Dio _dio;

  static const _retriedKey = 'auth_interceptor_retried';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storageService.getAccessToken();

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
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    if (_shouldSkipRefresh(err.requestOptions)) {
      return handler.next(err);
    }

    final refreshed = await _tokenRefreshService.refreshAccessToken();
    if (!refreshed) {
      return handler.next(err);
    }

    final newToken = await _storageService.getAccessToken();
    if (newToken == null || newToken.isEmpty) {
      return handler.next(err);
    }

    final retryOptions = err.requestOptions.copyWith(
      headers: {
        ...err.requestOptions.headers,
        'Authorization': 'Bearer $newToken',
      },
      extra: {
        ...err.requestOptions.extra,
        _retriedKey: true,
      },
    );

    try {
      final response = await _dio.fetch<dynamic>(retryOptions);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  bool _shouldSkipRefresh(RequestOptions options) {
    if (options.extra[_retriedKey] == true) {
      return true;
    }

    final path = options.uri.path.toLowerCase();
    return path.contains('/auth/refresh') ||
        path.contains('/auth/login') ||
        path.contains('/auth/logout') ||
        path.contains('/auth/register') ||
        path.contains('/device-link');
  }
}
