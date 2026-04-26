/// Authentication & User Management API endpoint constants
class AuthEndpoints {
  // Base URLs (Standardized via Traefik rewriters)
  static const String authBaseUrl = 'https://am.asrax.in/auth';
  static const String userBaseUrl = 'https://am.asrax.in/users';
  
  // Authentication endpoints
  static const String login = '$userBaseUrl/api/v1/auth/login'; // Standard Login (via User Mgmt)
  static const String logout = '$authBaseUrl/logout';
  static const String refreshToken = '$authBaseUrl/refresh';
  static const String googleLogin = '$authBaseUrl/auth/google/token';
  
  // User Management endpoints
  static const String register = '$userBaseUrl/api/v1/auth/register';
  static const String forgotPassword = '$userBaseUrl/forgot-password';
  static const String resetPassword = '$userBaseUrl/reset-password';
  static const String userProfile = '$userBaseUrl/profile';
  static const String updateProfile = '$userBaseUrl/profile';
  
  /// Get user status endpoint (for activation/status check)
  static String userStatus(String userId) => 
      '$userBaseUrl/$userId/status';
}
