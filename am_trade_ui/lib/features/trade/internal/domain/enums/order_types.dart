import 'package:json_annotation/json_annotation.dart';

/// Order types for trade execution
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum OrderTypes { market, limit, stopLoss, stopLossMarket }

/// Extension for OrderTypes enum
extension OrderTypesExtension on OrderTypes {
  String get displayName {
    switch (this) {
      case OrderTypes.market:
        return 'Market';
      case OrderTypes.limit:
        return 'Limit';
      case OrderTypes.stopLoss:
        return 'Stop Loss';
      case OrderTypes.stopLossMarket:
        return 'Stop Loss Market';
    }
  }
}
