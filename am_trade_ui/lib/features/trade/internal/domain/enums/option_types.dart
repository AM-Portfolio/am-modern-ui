import 'package:json_annotation/json_annotation.dart';

/// Option types for derivatives
enum OptionTypes {
  @JsonValue('CALL')
  call,
  @JsonValue('PUT')
  put,
  @JsonValue('UNKNOWN')
  unknown,
}

/// Custom converter for OptionTypes to handle various API formats
class OptionTypesConverter implements JsonConverter<OptionTypes?, String?> {
  const OptionTypesConverter();

  @override
  OptionTypes? fromJson(String? json) {
    if (json == null) return null;

    final normalized = json.trim().toUpperCase();

    switch (normalized) {
      case 'CALL':
      case 'C':
      case 'CE': // Call European (NSE India)
      case 'CA': // Call American
        return OptionTypes.call;
      case 'PUT':
      case 'P':
      case 'PE': // Put European (NSE India)
      case 'PA': // Put American
        return OptionTypes.put;
      default:
        return OptionTypes.unknown;
    }
  }

  @override
  String? toJson(OptionTypes? value) {
    if (value == null) return null;

    switch (value) {
      case OptionTypes.call:
        return 'CALL';
      case OptionTypes.put:
        return 'PUT';
      case OptionTypes.unknown:
        return 'UNKNOWN';
    }
  }
}

/// Extension for OptionTypes enum
extension OptionTypesExtension on OptionTypes {
  String get displayName {
    switch (this) {
      case OptionTypes.call:
        return 'Call';
      case OptionTypes.put:
        return 'Put';
      case OptionTypes.unknown:
        return 'Unknown';
    }
  }
}
