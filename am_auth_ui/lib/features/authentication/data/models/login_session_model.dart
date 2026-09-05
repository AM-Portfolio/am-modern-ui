class LoginSessionModel {
  const LoginSessionModel({
    required this.sessionId,
    required this.clientType,
    required this.createdAt,
    required this.lastActiveAt,
    this.browser,
    this.os,
    this.geoCity,
    this.geoCountry,
    this.ipMasked,
    this.machineLabel,
    this.current = false,
  });

  final String sessionId;
  final String? browser;
  final String? os;
  final String clientType;
  final String? geoCity;
  final String? geoCountry;
  final String? ipMasked;
  final String? machineLabel;
  final double createdAt;
  final double lastActiveAt;
  final bool current;

  factory LoginSessionModel.fromJson(Map<String, dynamic> json) {
    return LoginSessionModel(
      sessionId: json['session_id'] as String,
      browser: json['browser'] as String?,
      os: json['os'] as String?,
      clientType: json['client_type'] as String,
      geoCity: json['geo_city'] as String?,
      geoCountry: json['geo_country'] as String?,
      ipMasked: json['ip_masked'] as String?,
      machineLabel: json['machine_label'] as String?,
      createdAt: (json['created_at'] as num).toDouble(),
      lastActiveAt: (json['last_active_at'] as num).toDouble(),
      current: json['current'] as bool? ?? false,
    );
  }

  String get deviceLabel {
    if (machineLabel != null && machineLabel!.isNotEmpty) {
      return machineLabel!;
    }
    if (clientType == 'mobile') {
      return 'AM App${os != null ? ' · $os' : ''}';
    }
    final browserLabel = browser ?? 'Browser';
    return '$browserLabel${os != null ? ' · $os' : ''}';
  }

  String get locationLabel {
    final parts = <String>[
      if (geoCity != null && geoCity!.isNotEmpty) geoCity!,
      if (geoCountry != null && geoCountry!.isNotEmpty) geoCountry!,
    ];
    return parts.isEmpty ? 'Unknown location' : parts.join(', ');
  }
}
