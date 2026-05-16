import 'package:am_common/am_common.dart';
import 'package:dio/dio.dart';
import 'package:am_auth_ui/core/constants/auth_endpoints.dart';
import 'package:am_design_system/core/constants/auth_constants.dart';
import 'package:am_design_system/core/errors/exceptions.dart';
import 'package:am_design_system/core/errors/exceptions.dart';
import '../models/auth_result_model.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';
import 'auth_data_source.dart';

/// Real API implementation of authentication data source
class AuthRemoteDataSource implements AuthDataSource {
  AuthRemoteDataSource(this._dio);
  final Dio _dio;

  @override
  Future<AuthResultModel> emailLogin(String email, String password) async {
    try {
      final fullUrl = AuthEndpoints.login;
      AppLogger.info('🔵 [AuthRemoteDataSource] User Mgmt Login URL: $fullUrl');
      final response = await _dio.post(
        fullUrl,
        data: {'username': email, 'password': password}, // Centralized auth service (am-auth-tokens) uses 'username'
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        var userId = data['user_id'] ?? data['id'] ?? data['_id'] ?? data['userId'] ?? '';


        if (userId.toString().isEmpty) {
          AppLogger.error('🚨 CRITICAL: Login response has empty User ID! Data keys: ${data.keys.toList()}');
        }

        final user = UserModel(
          id: userId.toString(),
          email: data['email'] ?? email,
          displayName: data['username'] ?? data['name'] ?? data['full_name'],
          authMethod: AuthConstants.authMethodEmail,
        );

        final tokens = AuthTokensModel(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          expiresAt: DateTime.now().add(
            Duration(seconds: data['expires_in'] ?? 3600),
          ),
        );

        return AuthResultModel(user: user, tokens: tokens);
      } else {
        throw ServerException(
          'Login failed',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      // More detailed error handling using AppLogger
      AppLogger.error(
        'Login API Error',
        tag: 'AuthRemoteDataSource',
        error: e.response?.data,
      );

      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw NetworkException(AuthConstants.networkError);
      }

      var errorMessage = AuthConstants.serverError;
      if (e.response?.data != null && e.response!.data is Map) {
        final data = e.response!.data;
        errorMessage =
            data['message'] ?? data['detail'] ?? data['error'] ?? errorMessage;
      }

      throw ServerException(
        errorMessage,
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }


  @override
  Future<AuthResultModel> googleLogin(String idToken) async {
    try {
      AppLogger.info('🔵 [BACKEND] Preparing Google OAuth request...');

      final fullUrl = AuthEndpoints.googleLogin;

      AppLogger.info('🔵 [BACKEND] POST $fullUrl');
      AppLogger.debug('🔵 [BACKEND] ID Token length: ${idToken.length}');

      final response = await _dio.post(
        fullUrl,
        data: {'id_token': idToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      AppLogger.info('🔵 [BACKEND] Response Status: ${response.statusCode}');
      AppLogger.debug('🔵 [BACKEND] Response Data: ${response.data}');

      if (response.statusCode == 200) {
        AppLogger.info('🔵 [BACKEND] ✅ Success! Parsing response...');
        
        // Backend returns flat structure, need to parse manually
        final data = response.data as Map<String, dynamic>;
        
        final user = UserModel(
          id: data['user']['id'] as String,
          email: data['user']['email'] as String,
          displayName: data['user']['name'] as String?,
          photoUrl: data['user']['picture'] as String?,
          authMethod: 'google',
        );
        
        final tokens = AuthTokensModel(
          accessToken: data['access_token'] as String,
          refreshToken: data['refresh_token']  as String?,
          expiresAt: DateTime.now().add(
            Duration(seconds: data['expires_in'] as int? ?? 3600),
          ),
        );
        
        final model = AuthResultModel(user: user, tokens: tokens);
        
        print('✅ [BACKEND] Parsed user: ${model.user.email}, ID: ${model.user.id}');
        AppLogger.info('🔵 [BACKEND] Parsed user: ${model.user.email}');
        return model;
      } else {
        AppLogger.error(
          '🔴 [BACKEND] Unexpected status: ${response.statusCode}',
        );
        throw ServerException(
          'Google login failed',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      AppLogger.error(
        '🔴 [BACKEND] DioException occurred',
        tag: 'AuthRemoteDataSource',
        error: e,
      );
      
      AppLogger.error('🔴 [BACKEND] DioException occurred');
      AppLogger.error('🔴 [BACKEND] Type: ${e.type}');
      AppLogger.error('🔴 [BACKEND] Message: ${e.message}');
      AppLogger.error('🔴 [BACKEND] Response: ${e.response?.data}');
      AppLogger.error('🔴 [BACKEND] Status Code: ${e.response?.statusCode}');

      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw NetworkException(AuthConstants.networkError);
      }

      var errorMessage = AuthConstants.serverError;
      if (e.response?.data != null && e.response!.data is Map) {
        final data = e.response!.data;
        errorMessage =
            data['message'] ?? data['detail'] ?? data['error'] ?? errorMessage;
        AppLogger.error('🔴 [BACKEND] Error detail: $errorMessage');
      }

      throw ServerException(
        errorMessage,
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  @override
  Future<AuthResultModel> demoLogin() async {
    // Demo login might still call backend or use mock
    return emailLogin(AuthConstants.demoEmail, AuthConstants.demoPassword);
  }

  @override
  Future<void> logout() async {
    try {
      final fullUrl = AuthEndpoints.logout;
      await _dio.post(fullUrl);
    } on DioException catch (e) {
      // Log but don't throw - logout should always succeed locally
      AppLogger.error('Logout API call failed', tag: 'AuthRemoteDataSource', error: e);
    }
  }

  @override
  Future<AuthTokensModel> refreshToken(String refreshToken) async {
    try {
      final fullUrl = AuthEndpoints.refreshToken;
      final response = await _dio.post(
        fullUrl,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        return AuthTokensModel.fromJson(response.data);
      } else {
        throw ServerException(
          'Token refresh failed',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw NetworkException(AuthConstants.networkError);
      }
      throw ServerException(
        e.message ?? AuthConstants.serverError,
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  @override
  Future<AuthResultModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final fullUrl = AuthEndpoints.register;
      final response = await _dio.post(
        fullUrl,
        data: {
          'full_name': name,
          'email': email,
          'password': password,
          if (phone != null) 'phone_number': phone,
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        // The register endpoint might return the user and token immediately or just success
        // Based on Postman "Register New User", it returns user_id.
        // Postman test scripts implies json response.
        // Assuming it automagically logs in or we just return the user?
        // Let's assume it might NOT log in automatically,
        // but our AuthResultModel requires tokens.
        // If the API doesn't return tokens on register, we might need to call login immediately.

        // Postman response check:
        // pm.environment.set("user_id", jsonData.user_id);

        if (data['status'] == 'pending_verification') {
          final userId = data['user_id'] ?? 'unknown';
          throw ServerException(
            'Account created! User ID: $userId\\nPlease activate via Developer Controls to login.',
            statusCode: 201,
          );
        }

        // Use Login flow after register if tokens are missing?
        if (data['access_token'] == null) {
          return emailLogin(email, password);
        }

        // robust ID parsing for registration
        var userId = data['user_id'] ?? data['id'] ?? data['_id'] ?? data['userId'] ?? '';

        final user = UserModel(
          id: userId.toString(),
          email: data['email'] ?? email,
          displayName: data['full_name'] ?? name,
          authMethod: AuthConstants.authMethodEmail,
        );

        final tokens = AuthTokensModel(
          accessToken: data['access_token'],
          refreshToken:
              data['refresh_token'], // May be null if only access token
          expiresAt: DateTime.now().add(
            Duration(seconds: data['expires_in'] ?? 3600),
          ),
        );

        return AuthResultModel(user: user, tokens: tokens);
      } else {
        throw ServerException(
          'Registration failed',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      // DEBUG LOGGING
      AppLogger.error(
        'Registration API Error: ${e.message}',
        tag: 'AuthRemoteDataSource',
        error: e,
      );
      if (e.response != null) {
        AppLogger.error(
          'Response Data: ${e.response?.data}',
          tag: 'AuthRemoteDataSource',
        );
        AppLogger.error(
          'Status Code: ${e.response?.statusCode}',
          tag: 'AuthRemoteDataSource',
        );
      }

      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw NetworkException(AuthConstants.networkError);
      }

      var errorMessage = 'Registration failed';
      if (e.response?.data != null && e.response!.data is Map) {
        final data = e.response!.data;
        errorMessage =
            data['message'] ?? data['detail'] ?? data['error'] ?? errorMessage;
      }

      throw ServerException(
        errorMessage,
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    // Check with backend
    try {
      // Best bet: Trust the stored token until 401.
      return true; // Optimistic check, let interceptors handle 401s
    } catch (e) {
      return false;
    }
  }
}

