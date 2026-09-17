
import 'package:am_common/am_common.dart';

/// Authentication-related constants
class AuthConstants {
  // Error messages
  static const String invalidCredentials = 'Invalid email or password';
  static const String networkError =
      'Network error. Please check your connection';
  static const String serverError = 'Server error. Please try again later';
  static const String googleSignInCancelled = 'Google Sign-In was cancelled';
  static const String googleSignInFailed = 'Google Sign-In failed';
  static const String googleSignInNotConfigured =
      'Google Sign-In is not configured. Set google.webClientId in config '
      'or AM_GOOGLE_CLIENT_ID.';
  static const String tokenExpired = 'Session expired. Please login again';
  static const String unknownError = 'An unknown error occurred';

  // Success messages
  static const String loginSuccess = 'Login successful!';
  static const String logoutSuccess = 'Logged out successfully';
  static const String demoLoginSuccess = 'Welcome to demo mode!';

  // Demo user credentials (overridable via AM_DEMO_EMAIL / AM_DEMO_PASSWORD)
  static String get demoEmail => DemoLoginConfig.email;
  static String get demoPassword => DemoLoginConfig.password;

  /// Google Web OAuth client ID from dart-define only (no hardcoded product ID).
  /// Prefer [ConfigService.config.google.webClientId] at runtime.
  static const String googleClientId = String.fromEnvironment(
    'AM_GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  // Token settings
  static const Duration tokenExpiryDuration = Duration(hours: 24);
  static const Duration refreshTokenExpiryDuration = Duration(days: 30);

  // API endpoints are now managed in ApiEndpoints class and read from AppProperties

  // Shared preferences keys
  static const String isLoggedInKey = 'is_logged_in';
  static const String lastLoginKey = 'last_login';
  static const String authMethodKey = 'auth_method';

  // Auth methods
  static const String authMethodEmail = 'email';
  static const String authMethodGoogle = 'google';
  static const String authMethodDemo = 'demo';
}

