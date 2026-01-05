import 'package:json_annotation/json_annotation.dart';

/// Dimensions for grouping metrics
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum GroupByDimensions { strategy, symbol, dayOfWeek, month, portfolio, tradeType, instrumentType, direction }

/// Extension for GroupByDimensions enum
extension GroupByDimensionsExtension on GroupByDimensions {
  String get displayName {
    switch (this) {
      case GroupByDimensions.strategy:
        return 'Strategy';
      case GroupByDimensions.symbol:
        return 'Symbol';
      case GroupByDimensions.dayOfWeek:
        return 'Day of Week';
      case GroupByDimensions.month:
        return 'Month';
      case GroupByDimensions.portfolio:
        return 'Portfolio';
      case GroupByDimensions.tradeType:
        return 'Trade Type';
      case GroupByDimensions.instrumentType:
        return 'Instrument Type';
      case GroupByDimensions.direction:
        return 'Direction';
    }
  }
}
