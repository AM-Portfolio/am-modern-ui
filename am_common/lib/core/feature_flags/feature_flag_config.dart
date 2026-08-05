class FeatureFlagConfig {
  const FeatureFlagConfig({
    required this.enabled,
    required this.apiHost,
    required this.clientKey,
  });

  final bool enabled;
  final String apiHost;
  final String clientKey;

  static const disabled = FeatureFlagConfig(
    enabled: false,
    apiHost: '',
    clientKey: '',
  );

  factory FeatureFlagConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return disabled;
    final key = json['clientKey']?.toString() ?? '';
    final host = json['apiHost']?.toString() ?? '';
    final enabledRaw = json['enabled'];
    final enabled = enabledRaw == true ||
        (enabledRaw == null && key.isNotEmpty && host.isNotEmpty);
    if (!enabled || key.isEmpty || host.isEmpty) {
      return FeatureFlagConfig(
        enabled: false,
        apiHost: host,
        clientKey: key,
      );
    }
    return FeatureFlagConfig(
      enabled: true,
      apiHost: host.endsWith('/') ? host.substring(0, host.length - 1) : host,
      clientKey: key,
    );
  }
}
