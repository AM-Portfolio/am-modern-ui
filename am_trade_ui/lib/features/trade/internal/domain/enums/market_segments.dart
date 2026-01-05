import 'package:json_annotation/json_annotation.dart';

/// Market segments for trade filtering
enum MarketSegments {
  @JsonValue('EQUITY')
  equity,
  @JsonValue('INDEX_SEGMENT')
  indexSegment,
  @JsonValue('EQUITY_FUTURES')
  equityFutures,
  @JsonValue('INDEX_FUTURES')
  indexFutures,
  @JsonValue('EQUITY_OPTIONS')
  equityOptions,
  @JsonValue('INDEX_OPTIONS')
  indexOptions,
  @JsonValue('UNKNOWN')
  unknown,
}

/// Converter to handle market segment values
class MarketSegmentsConverter implements JsonConverter<MarketSegments?, String?> {
  const MarketSegmentsConverter();

  @override
  MarketSegments? fromJson(String? json) {
    if (json == null) return null;

    // Normalize the input (uppercase, handle different formats)
    final normalized = json.toUpperCase().trim();

    switch (normalized) {
      case 'EQUITY':
        return MarketSegments.equity;
      case 'INDEX_SEGMENT':
      case 'INDEX':
        return MarketSegments.indexSegment;
      case 'EQUITY_FUTURES':
      case 'EQ_FUTURES':
        return MarketSegments.equityFutures;
      case 'INDEX_FUTURES':
      case 'IDX_FUTURES':
        return MarketSegments.indexFutures;
      case 'EQUITY_OPTIONS':
      case 'EQ_OPTIONS':
        return MarketSegments.equityOptions;
      case 'INDEX_OPTIONS':
      case 'IDX_OPTIONS':
        return MarketSegments.indexOptions;
      case 'UNKNOWN':
      default:
        return MarketSegments.unknown;
    }
  }

  @override
  String? toJson(MarketSegments? segment) {
    if (segment == null) return null;

    switch (segment) {
      case MarketSegments.equity:
        return 'EQUITY';
      case MarketSegments.indexSegment:
        return 'INDEX_SEGMENT';
      case MarketSegments.equityFutures:
        return 'EQUITY_FUTURES';
      case MarketSegments.indexFutures:
        return 'INDEX_FUTURES';
      case MarketSegments.equityOptions:
        return 'EQUITY_OPTIONS';
      case MarketSegments.indexOptions:
        return 'INDEX_OPTIONS';
      case MarketSegments.unknown:
        return 'UNKNOWN';
    }
  }
}

/// Extension for MarketSegments enum
extension MarketSegmentsExtension on MarketSegments {
  String get displayName {
    switch (this) {
      case MarketSegments.equity:
        return 'Equity';
      case MarketSegments.indexSegment:
        return 'Index';
      case MarketSegments.equityFutures:
        return 'Equity Futures';
      case MarketSegments.indexFutures:
        return 'Index Futures';
      case MarketSegments.equityOptions:
        return 'Equity Options';
      case MarketSegments.indexOptions:
        return 'Index Options';
      case MarketSegments.unknown:
        return 'Unknown';
    }
  }
}
