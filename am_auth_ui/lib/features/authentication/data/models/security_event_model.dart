class SecurityEventModel {
  const SecurityEventModel({
    required this.eventId,
    required this.type,
    required this.createdAt,
    required this.acknowledged,
    this.sessionId,
    this.deviceLabel,
    this.geoCity,
    this.geoCountry,
  });

  final String eventId;
  final String type;
  final String? sessionId;
  final String? deviceLabel;
  final String? geoCity;
  final String? geoCountry;
  final double createdAt;
  final bool acknowledged;

  factory SecurityEventModel.fromJson(Map<String, dynamic> json) {
    return SecurityEventModel(
      eventId: json['event_id'] as String,
      type: json['type'] as String,
      sessionId: json['session_id'] as String?,
      deviceLabel: json['device_label'] as String?,
      geoCity: json['geo_city'] as String?,
      geoCountry: json['geo_country'] as String?,
      createdAt: (json['created_at'] as num).toDouble(),
      acknowledged: json['acknowledged'] as bool? ?? false,
    );
  }

  String get locationLabel {
    final parts = <String>[
      if (deviceLabel != null && deviceLabel!.isNotEmpty) deviceLabel!,
      if (geoCity != null && geoCity!.isNotEmpty) geoCity!,
      if (geoCountry != null && geoCountry!.isNotEmpty) geoCountry!,
    ];
    return parts.join(' · ');
  }
}
