class DeviceLinkStartResult {
  const DeviceLinkStartResult({
    required this.deviceLinkId,
    required this.qrPayload,
    required this.confirmationCode,
    required this.expiresAt,
    this.pollIntervalMs = 2000,
  });

  final String deviceLinkId;
  final Map<String, dynamic> qrPayload;
  final String confirmationCode;
  final double expiresAt;
  final int pollIntervalMs;

  factory DeviceLinkStartResult.fromJson(Map<String, dynamic> json) {
    return DeviceLinkStartResult(
      deviceLinkId: json['device_link_id'] as String,
      qrPayload: Map<String, dynamic>.from(json['qr_payload'] as Map),
      confirmationCode: json['confirmation_code'] as String,
      expiresAt: (json['expires_at'] as num).toDouble(),
      pollIntervalMs: json['poll_interval_ms'] as int? ?? 2000,
    );
  }
}

class WebSessionTokens {
  const WebSessionTokens({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
  });

  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;

  factory WebSessionTokens.fromJson(Map<String, dynamic> json) {
    return WebSessionTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: json['expires_in'] as int?,
    );
  }
}

class DeviceLinkPollUser {
  const DeviceLinkPollUser({
    required this.sub,
    this.email,
    this.preferredUsername,
  });

  final String sub;
  final String? email;
  final String? preferredUsername;

  factory DeviceLinkPollUser.fromJson(Map<String, dynamic> json) {
    return DeviceLinkPollUser(
      sub: json['sub'] as String,
      email: json['email'] as String?,
      preferredUsername: json['preferred_username'] as String?,
    );
  }
}

class DeviceLinkPollResult {
  const DeviceLinkPollResult({
    required this.status,
    this.user,
    this.tokens,
  });

  final String status;
  final DeviceLinkPollUser? user;
  final WebSessionTokens? tokens;
}

class DeviceLinkPreview {
  const DeviceLinkPreview({
    required this.host,
    required this.confirmationCode,
    required this.isNewDevice,
    required this.requestedAt,
    this.browser,
    this.os,
    this.geoCity,
    this.geoCountry,
    this.ipMasked,
  });

  final String host;
  final String confirmationCode;
  final String? browser;
  final String? os;
  final String? geoCity;
  final String? geoCountry;
  final String? ipMasked;
  final bool isNewDevice;
  final double requestedAt;

  factory DeviceLinkPreview.fromJson(Map<String, dynamic> json) {
    return DeviceLinkPreview(
      host: json['host'] as String,
      confirmationCode: json['confirmation_code'] as String,
      browser: json['browser'] as String?,
      os: json['os'] as String?,
      geoCity: json['geo_city'] as String?,
      geoCountry: json['geo_country'] as String?,
      ipMasked: json['ip_masked'] as String?,
      isNewDevice: json['is_new_device'] as bool? ?? false,
      requestedAt: (json['requested_at'] as num).toDouble(),
    );
  }
}
