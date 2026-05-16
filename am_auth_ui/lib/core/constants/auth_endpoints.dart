import 'package:am_common/am_common.dart';

/// Authentication & User Management API endpoint constants
class AuthEndpoints {
  // Base URLs (Standardized via Traefik rewriters)
  static String get authBaseUrl =>
      ConfigService.config.api.auth?.baseUrl ?? 'https://am.asrax.in/auth';
  static String get userBaseUrl =>
      ConfigService.config.api.user?.baseUrl ?? 'https://am.asrax.in/users';

  // Authentication endpoints
  static String get login =>
      '$authBaseUrl/v1/tokens'; // Centralized Token Service (am-auth-tokens)
  static String get logout => '$authBaseUrl/v1/auth/logout';
  static String get refreshToken => '$authBaseUrl/v1/auth/refresh';
  static String get googleLogin => '$authBaseUrl/v1/auth/google/token';

  // User Management endpoints
  static String get register => '$userBaseUrl/v1/auth/register';
  static String get forgotPassword => '$userBaseUrl/v1/auth/request-reset';
  static String get resetPassword => '$userBaseUrl/v1/auth/confirm-reset';
  static String get userProfile => '$userBaseUrl/v1/auth/status';
  static String get updateProfile => '$userBaseUrl/v1/auth/status';

  /// Get user status endpoint (for activation/status check)
  static String userStatus(String userId) => '$userBaseUrl/v1/users/$userId/status';
}
