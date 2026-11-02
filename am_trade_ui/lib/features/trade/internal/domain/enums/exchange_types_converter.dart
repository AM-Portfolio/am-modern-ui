import 'package:json_annotation/json_annotation.dart';

import 'exchange_types.dart';

/// Tolerant exchange decode — accepts NSE, nse, Nse, etc.
class ExchangeTypesConverter implements JsonConverter<ExchangeTypes?, String?> {
  const ExchangeTypesConverter();

  @override
  ExchangeTypes? fromJson(String? json) {
    if (json == null || json.trim().isEmpty) return null;
    final n = json.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final v in ExchangeTypes.values) {
      if (v.name.toLowerCase() == n) return v;
      if (v.displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ==
          n) {
        return v;
      }
    }
    return null;
  }

  @override
  String? toJson(ExchangeTypes? object) => object?.displayName;
}
