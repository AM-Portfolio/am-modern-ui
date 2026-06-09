import 'package:am_common/am_common.dart';

/// Authentication & User Management API endpoint constants
class AuthEndpoints {
  // Base URLs (Standardized via Traefik rewriters)
  static String get authBaseUrl =>
      ConfigService.config.api.auth?.baseUrl ?? 'https://am-dev.asrax.in/auth';
  static String get userBaseUrl =>
      ConfigService.config.api.user?.baseUrl ?? 'https://am-dev.asrax.in/users';

  // Authentication endpoints
  static String get login =>
      '$authBaseUrl${ConfigService.config.api.auth?.loginEndpoint ?? '/v1/auth/login'}';
  static String get identityLogin => login;
  
  static String get logout => 
      '$authBaseUrl${ConfigService.config.api.auth?.logoutEndpoint ?? '/v1/auth/logout'}';
  static String get identityLogout => logout;
  
  static String get refreshToken => 
      '$authBaseUrl${ConfigService.config.api.auth?.refreshTokenEndpoint ?? '/v1/auth/refresh'}';
  static String get identityRefreshToken => refreshToken;
  
  static String get googleLogin => 
      '$authBaseUrl${ConfigService.config.api.auth?.googleLoginEndpoint ?? '/v1/auth/google'}';
  static String get identityGoogleLogin => googleLogin;

  // User Management endpoints
  static String get register => 
      '$userBaseUrl${ConfigService.config.api.user?.registerEndpoint ?? '/v1/user/register'}';
  static String get identityRegister => register;
  static String get forgotPassword => 
      '$userBaseUrl${ConfigService.config.api.user?.forgotPasswordEndpoint ?? '/v1/user/forgot-password'}';
  static String get resetPassword => 
      '$userBaseUrl${ConfigService.config.api.user?.resetPasswordEndpoint ?? '/v1/user/reset-password'}';
  static String get userProfile => '$userBaseUrl/profile';
  static String get updateProfile => '$userBaseUrl/profile';

  /// Get user status endpoint (for activation/status check)
  static String userStatus(String userId) => '$userBaseUrl/v1/users/$userId/status';
}
