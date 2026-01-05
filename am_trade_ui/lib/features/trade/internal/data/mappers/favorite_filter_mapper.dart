import '../../domain/entities/favorite_filter.dart';
import '../../domain/entities/filter_criteria.dart';
import '../../domain/entities/metrics_filter_config.dart';
import '../../domain/enums/derivative_types.dart';
import '../../domain/enums/index_types.dart';
import '../../domain/enums/market_segments.dart';
import '../../domain/enums/trade_directions.dart';
import '../../domain/enums/trade_statuses.dart';
import '../dtos/favorite_filter_dto.dart';
import '../dtos/metrics_filter_config_dto.dart';

/// Mapper for favorite filter between DTO and domain entity
class FavoriteFilterMapper {
  /// Convert FavoriteFilterResponseDto to FavoriteFilter domain entity
  static FavoriteFilter fromResponseDto(FavoriteFilterResponseDto dto) => FavoriteFilter(
    id: dto.id,
    name: dto.name,
    description: dto.description,
    filterConfig: MetricsFilterConfigMapper.fromDto(dto.filterConfig),
    createdAt: dto.createdAt != null ? DateTime.tryParse(dto.createdAt!) : null,
    updatedAt: dto.updatedAt != null ? DateTime.tryParse(dto.updatedAt!) : null,
    isDefault: dto.isDefault ?? false,
  );

  /// Convert FavoriteFilter entity to FavoriteFilterRequestDto
  static FavoriteFilterRequestDto toRequestDto(FavoriteFilter filter) => FavoriteFilterRequestDto(
    name: filter.name,
    description: filter.description,
    isDefault: filter.isDefault,
    filterConfig: MetricsFilterConfigMapper.toDto(filter.filterConfig),
  );

  /// Convert list of FavoriteFilterResponseDto to FavoriteFilterList entity
  static FavoriteFilterList fromListDto(List<FavoriteFilterResponseDto> dtos, String userId) =>
      FavoriteFilterList(userId: userId, filters: dtos.map(fromResponseDto).toList(), totalCount: dtos.length);

  /// Convert BulkDeleteResponseDto to BulkDeleteResult entity
  static BulkDeleteResult fromBulkDeleteDto(BulkDeleteResponseDto dto) =>
      BulkDeleteResult(deletedCount: dto.deletedCount, totalRequested: dto.totalRequested, message: dto.message);
}

/// Mapper for metrics filter config between DTO and domain entity
class MetricsFilterConfigMapper {
  /// Convert MetricsFilterConfigDto to MetricsFilterConfig domain entity
  static MetricsFilterConfig fromDto(MetricsFilterConfigDto dto) => MetricsFilterConfig(
    portfolioIds: dto.portfolioIds ?? [],
    dateRange: dto.dateRange != null ? _parseDateRange(dto.dateRange!) : null,
    timePeriod: dto.timePeriod?['period'] as String?,
    metricTypes: dto.metricTypes ?? [],
    groupBy: dto.groupBy ?? [],
    instruments: dto.instruments ?? [],
    instrumentFilters: dto.instrumentFilters != null
        ? InstrumentFilterCriteriaMapper.fromMap(dto.instrumentFilters!)
        : null,
    tradeCharacteristics: dto.tradeCharacteristics != null
        ? TradeCharacteristicsFilterMapper.fromMap(dto.tradeCharacteristics!)
        : null,
    profitLossFilters: dto.profitLossFilters != null ? ProfitLossFilterMapper.fromMap(dto.profitLossFilters!) : null,
  );

  /// Convert MetricsFilterConfig entity to MetricsFilterConfigDto
  static MetricsFilterConfigDto toDto(MetricsFilterConfig config) => MetricsFilterConfigDto(
    portfolioIds: config.portfolioIds.isNotEmpty ? config.portfolioIds : null,
    dateRange: config.dateRange != null ? _dateRangeToMap(config.dateRange!) : null,
    timePeriod: config.timePeriod != null ? {'period': config.timePeriod} : null,
    metricTypes: config.metricTypes.isNotEmpty ? config.metricTypes : null,
    groupBy: config.groupBy.isNotEmpty ? config.groupBy : null,
    instruments: config.instruments.isNotEmpty ? config.instruments : null,
    instrumentFilters: config.instrumentFilters != null
        ? InstrumentFilterCriteriaMapper.toMap(config.instrumentFilters!)
        : null,
    tradeCharacteristics: config.tradeCharacteristics != null
        ? TradeCharacteristicsFilterMapper.toMap(config.tradeCharacteristics!)
        : null,
    profitLossFilters: config.profitLossFilters != null
        ? ProfitLossFilterMapper.toMap(config.profitLossFilters!)
        : null,
  );

  static DateRangeFilter? _parseDateRange(Map<String, dynamic> map) {
    final startDateStr = map['startDate'] as String?;
    final endDateStr = map['endDate'] as String?;

    if (startDateStr == null || endDateStr == null) return null;

    final startDate = DateTime.tryParse(startDateStr);
    final endDate = DateTime.tryParse(endDateStr);

    if (startDate == null || endDate == null) return null;

    return DateRangeFilter(startDate: startDate, endDate: endDate);
  }

  static Map<String, dynamic> _dateRangeToMap(DateRangeFilter filter) => {
    'startDate': filter.startDate.toIso8601String().split('T')[0],
    'endDate': filter.endDate.toIso8601String().split('T')[0],
  };
}

/// Mapper for instrument filter criteria
class InstrumentFilterCriteriaMapper {
  /// Convert from Map to InstrumentFilterCriteria entity
  static InstrumentFilterCriteria fromMap(Map<String, dynamic> map) => InstrumentFilterCriteria(
    marketSegments: map['marketSegments'] != null
        ? (map['marketSegments'] as List)
              .map((e) => _parseMarketSegment(e as String))
              .whereType<MarketSegments>()
              .toList()
        : [],
    baseSymbols: map['baseSymbols'] != null ? List<String>.from(map['baseSymbols'] as List) : [],
    indexTypes: map['indexTypes'] != null
        ? (map['indexTypes'] as List).map((e) => _parseIndexType(e as String)).whereType<IndexTypes>().toList()
        : [],
    derivativeTypes: map['derivativeTypes'] != null
        ? (map['derivativeTypes'] as List)
              .map((e) => _parseDerivativeType(e as String))
              .whereType<DerivativeTypes>()
              .toList()
        : [],
  );

  /// Convert from InstrumentFilterCriteria entity to Map
  static Map<String, dynamic> toMap(InstrumentFilterCriteria criteria) {
    final map = <String, dynamic>{};

    if (criteria.marketSegments.isNotEmpty) {
      map['marketSegments'] = criteria.marketSegments.map(_marketSegmentToString).toList();
    }
    if (criteria.baseSymbols.isNotEmpty) {
      map['baseSymbols'] = criteria.baseSymbols;
    }
    if (criteria.indexTypes.isNotEmpty) {
      map['indexTypes'] = criteria.indexTypes.map(_indexTypeToString).toList();
    }
    if (criteria.derivativeTypes.isNotEmpty) {
      map['derivativeTypes'] = criteria.derivativeTypes.map(_derivativeTypeToString).toList();
    }

    return map;
  }

  static MarketSegments? _parseMarketSegment(String value) {
    switch (value.toUpperCase()) {
      case 'EQUITY':
        return MarketSegments.equity;
      case 'INDEX_SEGMENT':
        return MarketSegments.indexSegment;
      case 'EQUITY_FUTURES':
        return MarketSegments.equityFutures;
      case 'INDEX_FUTURES':
        return MarketSegments.indexFutures;
      case 'EQUITY_OPTIONS':
        return MarketSegments.equityOptions;
      case 'INDEX_OPTIONS':
        return MarketSegments.indexOptions;
      default:
        return null;
    }
  }

  static String _marketSegmentToString(MarketSegments segment) {
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

  static IndexTypes? _parseIndexType(String value) {
    switch (value.toUpperCase()) {
      case 'NIFTY':
        return IndexTypes.nifty;
      case 'BANKNIFTY':
        return IndexTypes.banknifty;
      case 'FINNIFTY':
        return IndexTypes.finnifty;
      case 'MIDCPNIFTY':
        return IndexTypes.midcpnifty;
      default:
        return null;
    }
  }

  static String _indexTypeToString(IndexTypes type) {
    switch (type) {
      case IndexTypes.nifty:
        return 'NIFTY';
      case IndexTypes.banknifty:
        return 'BANKNIFTY';
      case IndexTypes.finnifty:
        return 'FINNIFTY';
      case IndexTypes.midcpnifty:
        return 'MIDCPNIFTY';
    }
  }

  static DerivativeTypes? _parseDerivativeType(String value) {
    switch (value.toUpperCase()) {
      case 'FUTURES':
        return DerivativeTypes.futures;
      case 'OPTIONS':
        return DerivativeTypes.options;
      default:
        return null;
    }
  }

  static String _derivativeTypeToString(DerivativeTypes type) {
    switch (type) {
      case DerivativeTypes.futures:
        return 'FUTURES';
      case DerivativeTypes.options:
        return 'OPTIONS';
    }
  }
}

/// Mapper for trade characteristics filter
class TradeCharacteristicsFilterMapper {
  /// Convert from Map to TradeCharacteristicsFilter entity
  static TradeCharacteristicsFilter fromMap(Map<String, dynamic> map) => TradeCharacteristicsFilter(
    strategies: map['strategies'] != null ? List<String>.from(map['strategies'] as List) : [],
    tags: map['tags'] != null ? List<String>.from(map['tags'] as List) : [],
    directions: map['directions'] != null
        ? (map['directions'] as List)
              .map((e) => _parseTradeDirection(e as String))
              .whereType<TradeDirections>()
              .toList()
        : [],
    statuses: map['statuses'] != null
        ? (map['statuses'] as List).map((e) => _parseTradeStatus(e as String)).whereType<TradeStatuses>().toList()
        : [],
    minHoldingTimeHours: map['minHoldingTimeHours'] as int?,
    maxHoldingTimeHours: map['maxHoldingTimeHours'] as int?,
  );

  /// Convert from TradeCharacteristicsFilter entity to Map
  static Map<String, dynamic> toMap(TradeCharacteristicsFilter filter) {
    final map = <String, dynamic>{};

    if (filter.strategies.isNotEmpty) map['strategies'] = filter.strategies;
    if (filter.tags.isNotEmpty) map['tags'] = filter.tags;
    if (filter.directions.isNotEmpty) map['directions'] = filter.directions.map(_tradeDirectionToString).toList();
    if (filter.statuses.isNotEmpty) map['statuses'] = filter.statuses.map(_tradeStatusToString).toList();
    if (filter.minHoldingTimeHours != null) map['minHoldingTimeHours'] = filter.minHoldingTimeHours;
    if (filter.maxHoldingTimeHours != null) map['maxHoldingTimeHours'] = filter.maxHoldingTimeHours;

    return map;
  }

  static TradeDirections? _parseTradeDirection(String value) {
    switch (value.toUpperCase()) {
      case 'LONG':
        return TradeDirections.long;
      case 'SHORT':
        return TradeDirections.short;
      default:
        return null;
    }
  }

  static String _tradeDirectionToString(TradeDirections direction) {
    switch (direction) {
      case TradeDirections.long:
        return 'LONG';
      case TradeDirections.short:
        return 'SHORT';
    }
  }

  static TradeStatuses? _parseTradeStatus(String value) {
    switch (value.toUpperCase()) {
      case 'OPEN':
        return TradeStatuses.open;
      case 'WIN':
        return TradeStatuses.win;
      case 'LOSS':
        return TradeStatuses.loss;
      case 'BREAKEVEN':
      case 'BREAK_EVEN':
        return TradeStatuses.breakeven;
      default:
        return null;
    }
  }

  static String _tradeStatusToString(TradeStatuses status) {
    switch (status) {
      case TradeStatuses.open:
        return 'OPEN';
      case TradeStatuses.win:
        return 'WIN';
      case TradeStatuses.loss:
        return 'LOSS';
      case TradeStatuses.breakeven:
        return 'BREAK_EVEN';
    }
  }
}

/// Mapper for profit/loss filter
class ProfitLossFilterMapper {
  /// Convert from Map to ProfitLossFilter entity
  static ProfitLossFilter fromMap(Map<String, dynamic> map) => ProfitLossFilter(
    minProfitLoss: _toDouble(map['minProfitLoss']),
    maxProfitLoss: _toDouble(map['maxProfitLoss']),
    minPositionSize: _toDouble(map['minPositionSize']),
    maxPositionSize: _toDouble(map['maxPositionSize']),
  );

  /// Helper to safely convert int/double to double?
  static double? _toDouble(value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return null;
  }

  /// Convert from ProfitLossFilter entity to Map
  static Map<String, dynamic> toMap(ProfitLossFilter filter) {
    final map = <String, dynamic>{};

    if (filter.minProfitLoss != null) map['minProfitLoss'] = filter.minProfitLoss;
    if (filter.maxProfitLoss != null) map['maxProfitLoss'] = filter.maxProfitLoss;
    if (filter.minPositionSize != null) map['minPositionSize'] = filter.minPositionSize;
    if (filter.maxPositionSize != null) map['maxPositionSize'] = filter.maxPositionSize;

    return map;
  }
}
