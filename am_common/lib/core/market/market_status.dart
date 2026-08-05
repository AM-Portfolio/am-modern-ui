/// Live market open/closed status from am-market-data
/// `GET /v1/market-calendar/status`.
class MarketStatus {
  const MarketStatus({
    required this.exchange,
    required this.open,
    required this.reason,
    this.asOf,
    this.sessionStart,
    this.sessionEnd,
  });

  final String exchange;
  final bool open;
  final String reason;
  final DateTime? asOf;

  /// Exchange-local session start (`HH:mm:ss`), Asia/Kolkata for NSE.
  final String? sessionStart;

  /// Exchange-local session end (`HH:mm:ss`), Asia/Kolkata for NSE.
  final String? sessionEnd;

  factory MarketStatus.fromJson(Map<String, dynamic> json) {
    return MarketStatus(
      exchange: json['exchange']?.toString() ?? 'NSE',
      open: json['open'] == true,
      reason: json['reason']?.toString() ?? 'UNKNOWN',
      asOf: _parseInstant(json['asOf']),
      sessionStart: json['sessionStart']?.toString(),
      sessionEnd: json['sessionEnd']?.toString(),
    );
  }

  static DateTime? _parseInstant(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toUtc();
  }
}
