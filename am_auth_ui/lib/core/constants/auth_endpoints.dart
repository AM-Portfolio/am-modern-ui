/// Authentication & User Management API endpoint constants
class AuthEndpoints {
  // Base URLs (Standardized via Traefik rewriters)
  static const String authBaseUrl = 'https://www.munish.org/auth';
  static const String userBaseUrl = 'https://www.munish.org/user';
  
  // Authentication endpoints
  static const String login = '$authBaseUrl/api/v1/auth/login'; // Standard Login (via User Mgmt)
  static const String logout = '$authBaseUrl/logout';
  static const String refreshToken = '$authBaseUrl/refresh';
  static const String googleLogin = '$authBaseUrl/auth/google/token';
  
  // User Management endpoints
  static const String register = '$authBaseUrl/api/v1/auth/register';
  static const String forgotPassword = '$userBaseUrl/forgot-password';
  static const String resetPassword = '$userBaseUrl/reset-password';
  static const String userProfile = '$userBaseUrl/profile';
  static const String updateProfile = '$userBaseUrl/profile';
  
  /// Get user status endpoint (for activation/status check)
  static String userStatus(String userId) => 
      '$userBaseUrl/$userId/status';
}
