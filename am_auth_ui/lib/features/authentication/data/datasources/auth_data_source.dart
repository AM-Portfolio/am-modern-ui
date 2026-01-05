import '../models/auth_result_model.dart';
import '../models/auth_tokens_model.dart';

/// Interface for authentication data sources
abstract class AuthDataSource {
  /// Login with email and password
  Future<AuthResultModel> emailLogin(String email, String password);

  /// Google login
  Future<AuthResultModel> googleLogin(String idToken);

  /// Login with demo account
  Future<AuthResultModel> demoLogin();

  /// Logout
  Future<void> logout();

  /// Refresh token
  Future<AuthTokensModel> refreshToken(String refreshToken);

  /// Register with email and password
  Future<AuthResultModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  });

  /// Check if user is authenticated
  Future<bool> isAuthenticated();
}
