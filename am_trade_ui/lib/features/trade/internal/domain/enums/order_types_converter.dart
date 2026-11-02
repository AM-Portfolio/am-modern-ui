import 'package:json_annotation/json_annotation.dart';

import 'order_types.dart';

/// Tolerant order-type decode — accepts MARKET, Market, stop_loss, etc.
class OrderTypesConverter implements JsonConverter<OrderTypes?, String?> {
  const OrderTypesConverter();

  @override
  OrderTypes? fromJson(String? json) {
    if (json == null || json.trim().isEmpty) return null;
    final n = json.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final v in OrderTypes.values) {
      if (v.name.toLowerCase() == n) return v;
      if (v.displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ==
          n) {
        return v;
      }
    }
    return null;
  }

  @override
  String? toJson(OrderTypes? object) {
    if (object == null) return null;
    switch (object) {
      case OrderTypes.market:
        return 'MARKET';
      case OrderTypes.limit:
        return 'LIMIT';
      case OrderTypes.stopLoss:
        return 'STOP_LOSS';
      case OrderTypes.stopLossMarket:
        return 'STOP_LOSS_MARKET';
    }
  }
}
