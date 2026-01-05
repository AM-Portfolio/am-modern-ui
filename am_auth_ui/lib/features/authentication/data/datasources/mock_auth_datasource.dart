import 'package:am_design_system/core/constants/auth_constants.dart';
import 'package:am_design_system/core/errors/exceptions.dart';
import '../models/auth_result_model.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';
import '../services/mock_data_service.dart';
import 'auth_data_source.dart';

/// Mock implementation of authentication data source
class MockAuthDataSource implements AuthDataSource {
  MockAuthDataSource(this._mockDataService);
  final MockDataService _mockDataService;

  @override
  Future<AuthResultModel> emailLogin(String email, String password) async {
    try {
      final result = await _mockDataService.authenticateEmailPassword(email, password);
      if (result == null) {
        throw AuthException(AuthConstants.invalidCredentials, code: '401');
      }
      return result;
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Login failed: ${e.toString()}');
    }
  }


  @override
  Future<AuthResultModel> googleLogin(String idToken) async {
    try {
      final result = await _mockDataService.authenticateGoogle();
      return result;
    } catch (e) {
      throw AuthException(AuthConstants.googleSignInFailed, code: '401');
    }
  }

  @override
  Future<AuthResultModel> demoLogin() async {
    try {
      final result = await _mockDataService.authenticateDemo();
      return result;
    } catch (e) {
      throw AuthException('Demo login failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    // Mock logout - just delay
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<AuthTokensModel> refreshToken(String refreshToken) async {
    // Mock token refresh
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();
    final expiresAt = now.add(AuthConstants.tokenExpiryDuration);

    return AuthTokensModel(
      accessToken: 'mock_access_token_refreshed_${now.millisecondsSinceEpoch}',
      refreshToken:
          'mock_refresh_token_refreshed_${now.millisecondsSinceEpoch}',
      expiresAt: expiresAt,
    );
  }

  @override
  Future<AuthResultModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1000));

    if (email.contains('fail')) {
      throw ServerException('Mock registration failed', statusCode: 400);
    }

    // Return a new user and tokens
    final user = UserModel(
      id: 'mock_user_id',
      email: email,
      displayName: name,
      authMethod: 'email',
    );

    return AuthResultModel(
      user: user,
      tokens: AuthTokensModel(
        accessToken: 'mock_access_token',
        refreshToken: 'mock_refresh_token',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
  }

  @override
  Future<bool> isAuthenticated() async {
    // In mock mode, we'll check local storage
    // For now, return false
    return false;
  }
}
