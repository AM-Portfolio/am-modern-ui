import 'package:am_common/am_common.dart';

/// Authentication & User Management API endpoint constants
class AuthEndpoints {
  // Base URLs (Standardized via Traefik rewriters)
  static String get _scheme => ConfigService.domain.contains('localhost') || ConfigService.domain.contains('127.0.0.1') ? 'http' : 'https';
  
  static String get authBaseUrl =>
      ConfigService.config.api.auth?.baseUrl ??
      '$_scheme://${ConfigService.domain}/identity';
  static String get userBaseUrl =>
      ConfigService.config.api.user?.baseUrl ??
      '$_scheme://${ConfigService.domain}/users';
  static String get identityBaseUrl =>
      ConfigService.override('identity') ??
      ConfigService.override('auth') ??
      '$_scheme://${ConfigService.domain}/identity';

  // Identity authentication endpoints
  static String get identityLogin => '$identityBaseUrl/auth/login';
  static String get identityRegister => '$identityBaseUrl/auth/register';
  static String get identityLogout => '$identityBaseUrl/auth/logout';
  static String get identityRefreshToken => '$identityBaseUrl/auth/refresh';
  static String get identityGoogleLogin => '$identityBaseUrl/auth/google/token';
  static String get identityPasswordReset => '$identityBaseUrl/auth/password-reset';
  static String get identityPasswordResetConfirm =>
      '$identityBaseUrl/auth/password-reset/confirm';
  static String get identityVerifyEmailResend =>
      '$identityBaseUrl/auth/verify-email/resend';
  static String get identityVerifyEmailConfirm =>
      '$identityBaseUrl/auth/verify-email/confirm';
  static String get identityChangePassword =>
      '$identityBaseUrl/auth/change-password';

  // Authentication endpoints
  static String get login =>
      '$authBaseUrl/v1/tokens'; // Centralized Token Service (am-auth-tokens)
  static String get logout => '$authBaseUrl/v1/auth/logout';
  static String get refreshToken => '$authBaseUrl/v1/auth/refresh';
  static String get googleLogin => '$authBaseUrl/v1/auth/google/token';

  // User Management endpoints
  static String get register => '$userBaseUrl/v1/auth/register';
  static String get forgotPassword => identityPasswordReset;
  static String get resetPassword => identityPasswordResetConfirm;
  static String get verifyEmailConfirm => identityVerifyEmailConfirm;
  static String get verifyEmailResend => identityVerifyEmailResend;
  static String get userProfile => '$userBaseUrl/v1/auth/status';
  static String get updateProfile => '$userBaseUrl/v1/auth/status';

  /// Get user status endpoint (for activation/status check)
  static String userStatus(String userId) => '$userBaseUrl/v1/users/$userId/status';
}
