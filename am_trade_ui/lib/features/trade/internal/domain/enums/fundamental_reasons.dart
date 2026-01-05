import 'package:json_annotation/json_annotation.dart';

/// Fundamental analysis reasons for trade entry/exit
enum FundamentalReasons {
  @JsonValue('EARNINGS_BEAT')
  earningsBeat,
  @JsonValue('SECTOR_STRENGTH')
  sectorStrength,
  @JsonValue('MARKET_SENTIMENT')
  marketSentiment,
  @JsonValue('NEWS_CATALYST')
  newsCatalyst,
  @JsonValue('VALUATION')
  valuation,
  @JsonValue('GROWTH_PROSPECTS')
  growthProspects,
  @JsonValue('ECONOMIC_DATA')
  economicData,
  @JsonValue('SECTOR_ROTATION')
  sectorRotation,
  @JsonValue('UNKNOWN')
  unknown,
}

/// Converter for FundamentalReasons enum
class FundamentalReasonsConverter implements JsonConverter<FundamentalReasons?, String?> {
  const FundamentalReasonsConverter();

  @override
  FundamentalReasons? fromJson(String? json) {
    if (json == null) return null;

    final normalized = json.trim().toUpperCase().replaceAll(' ', '_');

    switch (normalized) {
      case 'EARNINGS_BEAT':
      case 'EARNINGS':
      case 'GOOD_EARNINGS':
        return FundamentalReasons.earningsBeat;
      case 'SECTOR_STRENGTH':
      case 'STRONG_SECTOR':
        return FundamentalReasons.sectorStrength;
      case 'MARKET_SENTIMENT':
      case 'SENTIMENT':
      case 'POSITIVE_SENTIMENT':
        return FundamentalReasons.marketSentiment;
      case 'NEWS_CATALYST':
      case 'NEWS':
      case 'CATALYST':
        return FundamentalReasons.newsCatalyst;
      case 'VALUATION':
      case 'VALUE':
      case 'UNDERVALUED':
        return FundamentalReasons.valuation;
      case 'GROWTH_PROSPECTS':
      case 'GROWTH':
      case 'FUTURE_GROWTH':
        return FundamentalReasons.growthProspects;
      case 'ECONOMIC_DATA':
      case 'ECONOMY':
      case 'MACRO_DATA':
      case 'GDP':
        return FundamentalReasons.economicData;
      case 'SECTOR_ROTATION':
      case 'ROTATION':
        return FundamentalReasons.sectorRotation;
      default:
        return FundamentalReasons.unknown;
    }
  }

  @override
  String? toJson(FundamentalReasons? value) {
    if (value == null) return null;

    switch (value) {
      case FundamentalReasons.earningsBeat:
        return 'EARNINGS_BEAT';
      case FundamentalReasons.sectorStrength:
        return 'SECTOR_STRENGTH';
      case FundamentalReasons.marketSentiment:
        return 'MARKET_SENTIMENT';
      case FundamentalReasons.newsCatalyst:
        return 'NEWS_CATALYST';
      case FundamentalReasons.valuation:
        return 'VALUATION';
      case FundamentalReasons.growthProspects:
        return 'GROWTH_PROSPECTS';
      case FundamentalReasons.economicData:
        return 'ECONOMIC_DATA';
      case FundamentalReasons.sectorRotation:
        return 'SECTOR_ROTATION';
      case FundamentalReasons.unknown:
        return 'UNKNOWN';
    }
  }
}

/// Extension for FundamentalReasons enum
extension FundamentalReasonsExtension on FundamentalReasons {
  String get displayName {
    switch (this) {
      case FundamentalReasons.earningsBeat:
        return 'Earnings Beat';
      case FundamentalReasons.sectorStrength:
        return 'Sector Strength';
      case FundamentalReasons.marketSentiment:
        return 'Market Sentiment';
      case FundamentalReasons.newsCatalyst:
        return 'News Catalyst';
      case FundamentalReasons.valuation:
        return 'Valuation';
      case FundamentalReasons.growthProspects:
        return 'Growth Prospects';
      case FundamentalReasons.economicData:
        return 'Economic Data';
      case FundamentalReasons.sectorRotation:
        return 'Sector Rotation';
      case FundamentalReasons.unknown:
        return 'Unknown';
    }
  }
}

/// List converter for FundamentalReasons
class FundamentalReasonsListConverter implements JsonConverter<List<FundamentalReasons>?, List<dynamic>?> {
  const FundamentalReasonsListConverter();

  @override
  List<FundamentalReasons>? fromJson(List<dynamic>? json) {
    if (json == null) return null;
    const converter = FundamentalReasonsConverter();
    return json.map((e) => converter.fromJson(e as String?)).whereType<FundamentalReasons>().toList();
  }

  @override
  List<dynamic>? toJson(List<FundamentalReasons>? values) {
    if (values == null) return null;
    const converter = FundamentalReasonsConverter();
    return values.map((e) => converter.toJson(e)).toList();
  }
}
