import 'package:json_annotation/json_annotation.dart';

/// Trade directions for filtering
enum TradeDirections {
  @JsonValue('LONG')
  long,
  @JsonValue('SHORT')
  short,
}

/// Custom converter for TradeDirections to handle BUY/SELL and LONG/SHORT
class TradeDirectionsConverter implements JsonConverter<TradeDirections, String> {
  const TradeDirectionsConverter();

  @override
  TradeDirections fromJson(String json) {
    switch (json.toUpperCase()) {
      case 'LONG':
      case 'BUY':
        return TradeDirections.long;
      case 'SHORT':
      case 'SELL':
        return TradeDirections.short;
      default:
        throw ArgumentError('Invalid TradeDirections value: $json');
    }
  }

  @override
  String toJson(TradeDirections direction) {
    switch (direction) {
      case TradeDirections.long:
        return 'LONG';
      case TradeDirections.short:
        return 'SHORT';
    }
  }
}

/// Extension for TradeDirections enum
extension TradeDirectionsExtension on TradeDirections {
  String get displayName {
    switch (this) {
      case TradeDirections.long:
        return 'Long';
      case TradeDirections.short:
        return 'Short';
    }
  }
}
