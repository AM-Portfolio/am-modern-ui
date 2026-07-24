import 'dart:convert';
import 'package:am_common/am_common.dart';
import 'package:dio/dio.dart';
import 'package:am_auth_ui/core/constants/auth_endpoints.dart';
import 'package:am_design_system/core/constants/auth_constants.dart';
import 'package:am_design_system/core/errors/exceptions.dart';
import '../models/auth_result_model.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';
import 'auth_data_source.dart';

/// Real API implementation of authentication data source for am-identity service
class IdentityAuthRemoteDataSource implements AuthDataSource {
  IdentityAuthRemoteDataSource(this._dio);
  final Dio _dio;

  UserModel _parseUserFromToken(String token, String defaultEmail) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Invalid JWT');

      String payload = parts[1];
      // Base64Url decode with padding
      int paddingCount = (4 - (payload.length % 4)) % 4;
      payload += '=' * paddingCount;
      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> claims = jsonDecode(decoded);

      final userId = claims['sub'] ?? claims['user_id'] ?? claims['id'] ?? '';
      final email = claims['email'] ?? defaultEmail;
      final name = claims['name'] ?? claims['preferred_username'] ?? claims['username'] ?? '';

      return UserModel(
        id: userId.toString(),
        email: email.toString(),
        displayName: name.toString().isNotEmpty ? name.toString() : null,
        authMethod: 'identity',
      );
    } catch (e) {
      AppLogger.error('🚨 Failed to parse user from JWT: $e');
      return UserModel(
        id: '',
        email: defaultEmail,
        displayName: null,
        authMethod: 'identity',
      );
    }
  }

  @override
  Future<AuthResultModel> emailLogin(String email, String password) async {
    try {
      final fullUrl = AuthEndpoints.identityLogin;
      AppLogger.info('🔵 [IdentityAuthRemoteDataSource] Login URL: $fullUrl');
      final response = await _dio.post(
        fullUrl,
        data: {'username': email, 'password': password},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String?;

        final user = _parseUserFromToken(accessToken, email);

        if (user.id.isEmpty) {
          AppLogger.error('🚨 CRITICAL: Decoded User ID is empty from access token!');
        }

        final tokens = AuthTokensModel(
          accessToken: accessToken,
          refreshToken: refreshToken,
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
      AppLogger.error('Identity Login API Error: ${e.response?.data}');
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw NetworkException(AuthConstants.networkError);
      }

      var errorMessage = AuthConstants.serverError;
      if (e.response?.data != null && e.response!.data is Map) {
        final data = e.response!.data;
        final detail = data['detail'];
        if (detail is Map) {
          errorMessage = detail['error_description']?.toString() ?? 
                         detail['message']?.toString() ?? 
                         detail['error']?.toString() ?? 
                         errorMessage;
        } else if (detail != null) {
          errorMessage = detail.toString();
        } else {
          errorMessage = data['message']?.toString() ?? 
                         data['error']?.toString() ?? 
                         errorMessage;
        }
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
      final fullUrl = AuthEndpoints.identityGoogleLogin;
      AppLogger.info('🔵 [IdentityAuthRemoteDataSource] POST $fullUrl');

      final response = await _dio.post(
        fullUrl,
        data: {'id_token': idToken},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String?;

        final user = _parseUserFromToken(accessToken, '');

        final tokens = AuthTokensModel(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: DateTime.now().add(
            Duration(seconds: data['expires_in'] as int? ?? 3600),
          ),
        );

        return AuthResultModel(user: user, tokens: tokens);
      } else {
        throw ServerException(
          'Google login failed',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Identity Google Login API Error: ${e.response?.data}');
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw NetworkException(AuthConstants.networkError);
      }

      var errorMessage = AuthConstants.serverError;
      if (e.response?.data != null && e.response!.data is Map) {
        final data = e.response!.data;
        final detail = data['detail'];
        if (detail is Map) {
          errorMessage = detail['error_description']?.toString() ?? 
                         detail['message']?.toString() ?? 
                         detail['error']?.toString() ?? 
                         errorMessage;
        } else if (detail != null) {
          errorMessage = detail.toString();
        } else {
          errorMessage = data['message']?.toString() ?? 
                         data['error']?.toString() ?? 
                         errorMessage;
        }
      }

      throw ServerException(
        errorMessage,
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  @override
  Future<AuthResultModel> demoLogin() async {
    return emailLogin(AuthConstants.demoEmail, AuthConstants.demoPassword);
  }

  @override
  Future<void> logout() async {
    try {
      final fullUrl = AuthEndpoints.identityLogout;
      // Keycloak logout requires refresh token to revoke it
      // Standard local storage service handles token clearing, 
      // but let's try calling backend first.
      // Since logout is void, we don't throw.
      await _dio.post(fullUrl);
    } catch (e) {
      AppLogger.error('Logout API call failed: $e');
    }
  }

  @override
  Future<AuthTokensModel> refreshToken(String refreshToken) async {
    try {
      final fullUrl = AuthEndpoints.identityRefreshToken;
      final response = await _dio.post(
        fullUrl,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return AuthTokensModel(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          expiresAt: DateTime.now().add(
            Duration(seconds: data['expires_in'] ?? 3600),
          ),
        );
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
      final fullUrl = AuthEndpoints.identityRegister;
      final names = name.trim().split(' ');
      final firstName = names.isNotEmpty ? names.first : name;
      final lastName = names.length > 1 ? names.sublist(1).join(' ') : '';

      final response = await _dio.post(
        fullUrl,
        data: {
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Email verification is required — do not auto-login (Keycloak required action).
        throw ServerException(
          'Check your email to verify your Asrax account before signing in.',
          statusCode: 201,
        );
      } else {
        throw ServerException(
          'Registration failed',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Identity Registration API Error: ${e.response?.data}');
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw NetworkException(AuthConstants.networkError);
      }

      var errorMessage = 'Registration failed';
      if (e.response?.data != null && e.response!.data is Map) {
        final data = e.response!.data;
        final detail = data['detail'];
        if (detail is Map) {
          errorMessage = detail['error_description']?.toString() ?? 
                         detail['message']?.toString() ?? 
                         detail['error']?.toString() ?? 
                         errorMessage;
        } else if (detail != null) {
          errorMessage = detail.toString();
        } else {
          errorMessage = data['message']?.toString() ?? 
                         data['error']?.toString() ?? 
                         errorMessage;
        }
      }

      throw ServerException(
        errorMessage,
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return true;
  }

  Future<void> requestPasswordReset(String email) async {
    await _postAccepted(
      AuthEndpoints.identityPasswordReset,
      {'email': email},
      action: 'Password reset request',
    );
  }

  Future<void> confirmPasswordReset({
    String? token,
    String? code,
    required String newPassword,
  }) async {
    final body = <String, dynamic>{'new_password': newPassword};
    final trimmedCode = code?.trim();
    final trimmedToken = token?.trim();
    if (trimmedCode != null && trimmedCode.isNotEmpty) {
      body['code'] = trimmedCode;
    } else if (trimmedToken != null && trimmedToken.isNotEmpty) {
      body['token'] = trimmedToken;
    }
    await _postAccepted(
      AuthEndpoints.identityPasswordResetConfirm,
      body,
      action: 'Password reset confirm',
      acceptCodes: const {200},
    );
  }

  Future<AuthResultModel> confirmVerifyEmail({String? token, String? code}) async {
    final body = <String, dynamic>{};
    final trimmedCode = code?.trim();
    final trimmedToken = token?.trim();
    if (trimmedCode != null && trimmedCode.isNotEmpty) {
      body['code'] = trimmedCode;
    } else if (trimmedToken != null && trimmedToken.isNotEmpty) {
      body['token'] = trimmedToken;
    }
    try {
      final response = await _dio.post(
        AuthEndpoints.identityVerifyEmailConfirm,
        data: body,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (response.statusCode != 200) {
        throw ServerException(
          'Verify email confirm failed',
          statusCode: response.statusCode ?? 500,
        );
      }
      final data = response.data as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      if (accessToken == null || accessToken.isEmpty) {
        throw ServerException(
          'Verify email confirm did not return a session',
          statusCode: 500,
        );
      }
      final refreshToken = data['refresh_token'] as String?;
      final user = _parseUserFromToken(accessToken, '');
      return AuthResultModel(
        user: user,
        tokens: AuthTokensModel(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: DateTime.now().add(
            Duration(seconds: data['expires_in'] as int? ?? 3600),
          ),
        ),
      );
    } on DioException catch (e) {
      AppLogger.error('Identity Verify Email Confirm Error: ${e.response?.data}');
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw NetworkException(AuthConstants.networkError);
      }

      var errorMessage = AuthConstants.serverError;
      if (e.response?.data != null && e.response!.data is Map) {
        final data = e.response!.data;
        final detail = data['detail'];
        if (detail is Map) {
          errorMessage = detail['error_description']?.toString() ??
              detail['message']?.toString() ??
              detail['error']?.toString() ??
              errorMessage;
        } else if (detail != null) {
          errorMessage = detail.toString();
        } else {
          errorMessage = data['message']?.toString() ??
              data['error']?.toString() ??
              errorMessage;
        }
      }

      throw ServerException(
        errorMessage,
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  Future<void> resendVerifyEmail(String email) async {
    await _postAccepted(
      AuthEndpoints.identityVerifyEmailResend,
      {'email': email},
      action: 'Verify email resend',
    );
  }

  Future<void> changePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _postAccepted(
      AuthEndpoints.identityChangePassword,
      {
        'email': email,
        'current_password': currentPassword,
        'new_password': newPassword,
      },
      action: 'Change password',
      acceptCodes: const {200},
    );
  }

  Future<void> _postAccepted(
    String url,
    Map<String, dynamic> data, {
    required String action,
    Set<int> acceptCodes = const {202, 200},
  }) async {
    try {
      final response = await _dio.post(
        url,
        data: data,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (!acceptCodes.contains(response.statusCode)) {
        throw ServerException(
          '$action failed',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Identity $action API Error: ${e.response?.data}');
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw NetworkException(AuthConstants.networkError);
      }
      var errorMessage = '$action failed';
      final body = e.response?.data;
      if (body is Map) {
        final detail = body['detail'];
        if (detail != null) {
          errorMessage = detail.toString();
        }
      }
      throw ServerException(
        errorMessage,
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }

  Future<void> requestAccountDeletion({
    required String token,
    required String feedback,
  }) async {
    final url = '${AuthEndpoints.identityBaseUrl}/users/me/request-deletion';
    try {
      final response = await _dio.post(
        url,
        data: {'feedback': feedback},
        options: Options(headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        }),
      );
      if (response.statusCode != 200) {
        throw ServerException(
          'Request account deletion failed',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      AppLogger.error('Identity Request account deletion API Error: ${e.response?.data}');
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw NetworkException(AuthConstants.networkError);
      }
      var errorMessage = 'Request account deletion failed';
      final body = e.response?.data;
      if (body is Map) {
        final detail = body['detail'];
        if (detail != null) {
          errorMessage = detail.toString();
        }
      }
      throw ServerException(
        errorMessage,
        statusCode: e.response?.statusCode ?? 500,
      );
    }
  }
}
