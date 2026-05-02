import 'package:am_common/am_common.dart';

/// Authentication & User Management API endpoint constants
class AuthEndpoints {
  // Base URLs (Standardized via Traefik rewriters)
  static String get authBaseUrl => ConfigService.config.api.auth?.baseUrl ?? 'https://am.asrax.in/auth';
  static String get userBaseUrl => ConfigService.config.api.user?.baseUrl ?? 'https://am.asrax.in/users';
  
  // Authentication endpoints
  static const String login = '$authBaseUrl/v1/tokens'; // Centralized Token Service (am-auth-tokens)
  static const String logout = '$authBaseUrl/logout';
  static const String refreshToken = '$authBaseUrl/refresh';
  static const String googleLogin = '$authBaseUrl/auth/google/token';
  
  // User Management endpoints
  static String get register => '$userBaseUrl/v1/auth/register';
  static String get forgotPassword => '$userBaseUrl/forgot-password';
  static String get resetPassword => '$userBaseUrl/reset-password';
  static String get userProfile => '$userBaseUrl/profile';
  static String get updateProfile => '$userBaseUrl/profile';
  
  /// Get user status endpoint (for activation/status check)
  static String userStatus(String userId) => 
      '$userBaseUrl/$userId/status';
}
