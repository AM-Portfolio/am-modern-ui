/// API model for broker holding data
/// Shared model used across portfolio holdings and summary responses
class BrokerHoldingDto {
  /// Constructor
  const BrokerHoldingDto({required this.brokerType, required this.quantity});

  /// Create from JSON response
  factory BrokerHoldingDto.fromJson(Map<String, dynamic> json) =>
      BrokerHoldingDto(
        brokerType: json['brokerType'] as String? ?? '',
        quantity: _parseDouble(json['quantity']),
      );

  /// Type/name of the broker
  final String brokerType;

  /// Quantity held with this broker
  final double quantity;

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'brokerType': brokerType,
    'quantity': quantity,
  };

  /// Helper method to safely parse double values from API
  static double _parseDouble(value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }
}
