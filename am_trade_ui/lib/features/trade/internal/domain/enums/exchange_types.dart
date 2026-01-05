import 'package:json_annotation/json_annotation.dart';

/// Exchange types for trading instruments
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum ExchangeTypes { nse, bse, mcx, ncdex }

/// Extension for ExchangeTypes enum
extension ExchangeTypesExtension on ExchangeTypes {
  String get displayName {
    switch (this) {
      case ExchangeTypes.nse:
        return 'NSE';
      case ExchangeTypes.bse:
        return 'BSE';
      case ExchangeTypes.mcx:
        return 'MCX';
      case ExchangeTypes.ncdex:
        return 'NCDEX';
    }
  }
}
