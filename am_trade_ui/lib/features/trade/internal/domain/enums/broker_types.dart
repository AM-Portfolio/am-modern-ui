import 'package:json_annotation/json_annotation.dart';

/// Broker types
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum BrokerTypes { zerodha, dhan, mstock, grow, kotak, angelOne, upstox, icici, hdfc, manual, other }

/// Extension for BrokerTypes enum
extension BrokerTypesExtension on BrokerTypes {
  String get displayName {
    switch (this) {
      case BrokerTypes.zerodha:
        return 'Zerodha';
      case BrokerTypes.dhan:
        return 'Dhan';
      case BrokerTypes.mstock:
        return 'MStock';
      case BrokerTypes.grow:
        return 'Grow';
      case BrokerTypes.kotak:
        return 'Kotak';
      case BrokerTypes.angelOne:
        return 'Angel One';
      case BrokerTypes.upstox:
        return 'Upstox';
      case BrokerTypes.icici:
        return 'ICICI Direct';
      case BrokerTypes.hdfc:
        return 'HDFC Securities';
      case BrokerTypes.manual:
        return 'Manual';
      case BrokerTypes.other:
        return 'Other';
    }
  }
}
