import 'package:json_annotation/json_annotation.dart';

import 'broker_types.dart';

/// Tolerant broker decode — accepts DHAN, Dhan, dhan, etc.
class BrokerTypesConverter implements JsonConverter<BrokerTypes?, String?> {
  const BrokerTypesConverter();

  static const _toWire = <BrokerTypes, String>{
    BrokerTypes.zerodha: 'ZERODHA',
    BrokerTypes.dhan: 'DHAN',
    BrokerTypes.mstock: 'MSTOCK',
    BrokerTypes.grow: 'GROW',
    BrokerTypes.kotak: 'KOTAK',
    BrokerTypes.angelOne: 'ANGEL_ONE',
    BrokerTypes.upstox: 'UPSTOX',
    BrokerTypes.icici: 'ICICI',
    BrokerTypes.hdfc: 'HDFC',
    BrokerTypes.manual: 'MANUAL',
    BrokerTypes.other: 'OTHER',
  };

  @override
  BrokerTypes? fromJson(String? json) {
    if (json == null || json.trim().isEmpty) return null;
    final n = json.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    for (final entry in _toWire.entries) {
      if (entry.value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ==
          n) {
        return entry.key;
      }
    }
    for (final v in BrokerTypes.values) {
      if (v.name.toLowerCase() == n) return v;
      if (v.displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') ==
          n) {
        return v;
      }
    }
    return null;
  }

  @override
  String? toJson(BrokerTypes? object) =>
      object == null ? null : _toWire[object];
}
