

/// Authentication-related constants
class AuthConstants {
  // Error messages
  static const String invalidCredentials = 'Invalid email or password';
  static const String networkError =
      'Network error. Please check your connection';
  static const String serverError = 'Server error. Please try again later';
  static const String googleSignInCancelled = 'Google Sign-In was cancelled';
  static const String googleSignInFailed = 'Google Sign-In failed';
  static const String tokenExpired = 'Session expired. Please login again';
  static const String unknownError = 'An unknown error occurred';

  // Success messages
  static const String loginSuccess = 'Login successful!';
  static const String logoutSuccess = 'Logged out successfully';
  static const String demoLoginSuccess = 'Welcome to demo mode!';

  // Demo user credentials
  static const String demoEmail = 'ssd2658@gmail.com';
  static const String demoPassword = '@M1unish';

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

