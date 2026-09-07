import 'package:dio/dio.dart';
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
    try {
      final token = await _storageService.getAccessToken();

      // Dio/web may hand back an unmodifiable headers map — copy before write.
      if (token != null && token.isNotEmpty) {
        options.headers = Map<String, dynamic>.from(options.headers);
        options.headers['Authorization'] = 'Bearer $token';
      }

      handler.next(options);
    } catch (e, st) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: e,
          stackTrace: st,
          type: DioExceptionType.unknown,
          message: 'Auth interceptor failed: $e',
        ),
      );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Determine if the error is 401 Unauthorized
    if (err.response?.statusCode == 401) {
      // Logic for refreshing token could go here or triggering logout
      // For now, we just pass the error through
      // But we might want to clear local storage if the session is definitely invalid
    }

    return handler.next(err);
  }
}
