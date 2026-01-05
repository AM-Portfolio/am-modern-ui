/// Authentication & User Management API endpoint constants
class AuthEndpoints {
  // Base URLs
  static const String authBaseUrl = 'http://localhost:8001/api/v1/auth';
  static const String userBaseUrl = 'http://localhost:8002/api/v1/user';
  
  // Authentication endpoints
  static const String login = '$authBaseUrl/login';
  static const String logout = '$authBaseUrl/logout';
  static const String refreshToken = '$authBaseUrl/refresh';
  static const String googleLogin = '$authBaseUrl/google';
  
  // User Management endpoints
  static const String register = '$userBaseUrl/register';
  static const String forgotPassword = '$userBaseUrl/forgot-password';
  static const String resetPassword = '$userBaseUrl/reset-password';
  static const String userProfile = '$userBaseUrl/profile';
  static const String updateProfile = '$userBaseUrl/profile';
  
  /// Get user status endpoint (for activation/status check)
  static String userStatus(String userId) => '$userBaseUrl/$userId/status';
}
