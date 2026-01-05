import 'package:json_annotation/json_annotation.dart';

/// Broker types
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum BrokerTypes { zerodha, upstox, angel, icici, hdfc, other }

/// Extension for BrokerTypes enum
extension BrokerTypesExtension on BrokerTypes {
  String get displayName {
    switch (this) {
      case BrokerTypes.zerodha:
        return 'Zerodha';
      case BrokerTypes.upstox:
        return 'Upstox';
      case BrokerTypes.angel:
        return 'Angel One';
      case BrokerTypes.icici:
        return 'ICICI Direct';
      case BrokerTypes.hdfc:
        return 'HDFC Securities';
      case BrokerTypes.other:
        return 'Other';
    }
  }
}
