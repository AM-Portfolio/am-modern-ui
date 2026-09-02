import 'device_link_models.dart';

class WebOtpSendResult {
  const WebOtpSendResult({
    required this.otpSessionId,
    required this.expiresAt,
    required this.maskedDestination,
  });

  final String otpSessionId;
  final double expiresAt;
  final String maskedDestination;

  factory WebOtpSendResult.fromJson(Map<String, dynamic> json) {
    return WebOtpSendResult(
      otpSessionId: json['otp_session_id'] as String,
      expiresAt: (json['expires_at'] as num).toDouble(),
      maskedDestination: json['masked_destination'] as String,
    );
  }
}

class WebOtpVerifyUser {
  const WebOtpVerifyUser({
    required this.sub,
    this.email,
    this.preferredUsername,
  });

  final String sub;
  final String? email;
  final String? preferredUsername;

  factory WebOtpVerifyUser.fromJson(Map<String, dynamic> json) {
    return WebOtpVerifyUser(
      sub: json['sub'] as String,
      email: json['email'] as String?,
      preferredUsername: json['preferred_username'] as String?,
    );
  }
}

class WebOtpVerifyResult {
  const WebOtpVerifyResult({
    required this.user,
    this.tokens,
  });

  final WebOtpVerifyUser user;
  final WebSessionTokens? tokens;

  factory WebOtpVerifyResult.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;
    WebSessionTokens? tokens;
    final tokensJson = json['tokens'];
    if (tokensJson is Map<String, dynamic>) {
      tokens = WebSessionTokens.fromJson(tokensJson);
    }
    return WebOtpVerifyResult(
      user: WebOtpVerifyUser.fromJson(userJson),
      tokens: tokens,
    );
  }
}
