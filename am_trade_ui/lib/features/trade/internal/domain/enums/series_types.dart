import 'package:json_annotation/json_annotation.dart';

/// Series types for equity and derivative instruments
enum SeriesTypes {
  @JsonValue('EQ')
  eq,
  @JsonValue('BE')
  be,
  @JsonValue('BZ')
  bz,
  @JsonValue('SM')
  sm,
  @JsonValue('ST')
  st,
  @JsonValue('FUT')
  fut,
  @JsonValue('OPT')
  opt,
  @JsonValue('UNKNOWN')
  unknown,
}

/// Custom converter for SeriesTypes to handle various API formats
class SeriesTypesConverter implements JsonConverter<SeriesTypes?, String?> {
  const SeriesTypesConverter();

  @override
  SeriesTypes? fromJson(String? json) {
    if (json == null) return null;

    final normalized = json.trim().toUpperCase();

    switch (normalized) {
      case 'EQ':
      case 'EQUITY':
        return SeriesTypes.eq;
      case 'BE':
      case 'BOOK_ENTRY':
        return SeriesTypes.be;
      case 'BZ':
      case 'B_SERIES':
        return SeriesTypes.bz;
      case 'SM':
      case 'SME':
        return SeriesTypes.sm;
      case 'ST':
      case 'SPOT_TRADE':
        return SeriesTypes.st;
      case 'FUT':
      case 'FUTURES':
        return SeriesTypes.fut;
      case 'OPT':
      case 'OPTIONS':
      case 'OPTION':
        return SeriesTypes.opt;
      default:
        return SeriesTypes.unknown;
    }
  }

  @override
  String? toJson(SeriesTypes? value) {
    if (value == null) return null;

    switch (value) {
      case SeriesTypes.eq:
        return 'EQ';
      case SeriesTypes.be:
        return 'BE';
      case SeriesTypes.bz:
        return 'BZ';
      case SeriesTypes.sm:
        return 'SM';
      case SeriesTypes.st:
        return 'ST';
      case SeriesTypes.fut:
        return 'FUT';
      case SeriesTypes.opt:
        return 'OPT';
      case SeriesTypes.unknown:
        return 'UNKNOWN';
    }
  }
}

/// Extension for SeriesTypes enum
extension SeriesTypesExtension on SeriesTypes {
  String get displayName {
    switch (this) {
      case SeriesTypes.eq:
        return 'EQ - Equity';
      case SeriesTypes.be:
        return 'BE - Book Entry';
      case SeriesTypes.bz:
        return 'BZ - B Series';
      case SeriesTypes.sm:
        return 'SM - SME';
      case SeriesTypes.st:
        return 'ST - Spot Trade';
      case SeriesTypes.fut:
        return 'FUT - Futures';
      case SeriesTypes.opt:
        return 'OPT - Options';
      case SeriesTypes.unknown:
        return 'Unknown';
    }
  }
}
