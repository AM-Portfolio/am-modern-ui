import 'package:json_annotation/json_annotation.dart';

part 'portfolio_analytics_response_dto.g.dart';

/// DTO for portfolio analytics response
@JsonSerializable()
class PortfolioAnalyticsResponseDto {
  const PortfolioAnalyticsResponseDto({
    this.portfolioId,
    this.timestamp,
    this.analytics,
  });

  factory PortfolioAnalyticsResponseDto.fromJson(Map<String, dynamic> json) =>
      _$PortfolioAnalyticsResponseDtoFromJson(json);
  final String? portfolioId;
  final String? timestamp;
  final AnalyticsDto? analytics;

  Map<String, dynamic> toJson() => _$PortfolioAnalyticsResponseDtoToJson(this);
}

/// Analytics data container
@JsonSerializable()
class AnalyticsDto {
  const AnalyticsDto({
    this.heatmap,
    this.movers,
    this.sectorAllocation,
    this.marketCapAllocation,
  });

  factory AnalyticsDto.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsDtoFromJson(json);
  final HeatmapDto? heatmap;
  final MoversDto? movers;
  final SectorAllocationDto? sectorAllocation;
  final MarketCapAllocationDto? marketCapAllocation;

  Map<String, dynamic> toJson() => _$AnalyticsDtoToJson(this);
}

/// Heatmap data for sector performance
@JsonSerializable()
class HeatmapDto {
  const HeatmapDto({this.sectors});

  factory HeatmapDto.fromJson(Map<String, dynamic> json) =>
      _$HeatmapDtoFromJson(json);
  final List<SectorDto>? sectors;

  Map<String, dynamic> toJson() => _$HeatmapDtoToJson(this);
}

/// Sector performance data
@JsonSerializable()
class SectorDto {
  const SectorDto({
    this.sectorName,
    this.performanceRank,
    this.performance,
    this.changePercent,
    this.weightage,
    this.color,
    this.stockCount,
    this.totalValue,
    this.totalReturnAmount,
    this.stocks,
  });

  factory SectorDto.fromJson(Map<String, dynamic> json) =>
      _$SectorDtoFromJson(json);
  final String? sectorName;
  final int? performanceRank;
  final double? performance;
  final double? changePercent;
  final double? weightage;
  final String? color;
  final int? stockCount;
  final double? totalValue;
  final double? totalReturnAmount;
  final List<StockDto>? stocks;

  Map<String, dynamic> toJson() => _$SectorDtoToJson(this);
}

/// Stock data in sector - supports multiple JSON formats
@JsonSerializable()
class StockDto {
  // Additional field for weight percentage

  const StockDto({
    this.symbol,
    this.companyName,
    this.lastPrice,
    this.changeAmount,
    this.changePercent,
    this.sector,
    this.quantity,
    this.avgPrice,
    this.marketValue,
    this.totalReturn,
    this.weight,
  });

  /// Custom factory to handle multiple JSON formats
  factory StockDto.fromJson(Map<String, dynamic> json) => StockDto(
    symbol: json['symbol'] as String?,
    // Handle both 'companyName' and 'name' fields
    companyName: (json['companyName'] ?? json['name']) as String?,
    // Handle both 'lastPrice' and 'price' fields
    lastPrice: (json['lastPrice'] ?? json['price'])?.toDouble(),
    // Handle both 'changeAmount' and 'change' fields
    changeAmount: (json['changeAmount'] ?? json['change'])?.toDouble(),
    changePercent: json['changePercent']?.toDouble(),
    sector: json['sector'] as String?,
    quantity: json['quantity']?.toDouble(),
    avgPrice: json['avgPrice']?.toDouble(),
    // Handle both 'marketValue' and 'value' fields
    marketValue: (json['marketValue'] ?? json['value'])?.toDouble(),
    totalReturn: json['totalReturn']?.toDouble(),
    weight: json['weight']?.toDouble(),
  );
  final String? symbol;
  final String? companyName;
  final double? lastPrice;
  final double? changeAmount;
  final double? changePercent;
  final String? sector;
  final double? quantity;
  final double? avgPrice;
  final double? marketValue;
  final double? totalReturn;
  final double? weight;

  Map<String, dynamic> toJson() => _$StockDtoToJson(this);
}

/// Movers data (top gainers and losers)
@JsonSerializable()
class MoversDto {
  const MoversDto({this.topGainers, this.topLosers});

  factory MoversDto.fromJson(Map<String, dynamic> json) =>
      _$MoversDtoFromJson(json);
  final List<StockDto>? topGainers;
  final List<StockDto>? topLosers;

  Map<String, dynamic> toJson() => _$MoversDtoToJson(this);
}

/// Sector allocation data
@JsonSerializable()
class SectorAllocationDto {
  const SectorAllocationDto({this.sectorWeights, this.industryWeights});

  factory SectorAllocationDto.fromJson(Map<String, dynamic> json) =>
      _$SectorAllocationDtoFromJson(json);
  final List<SectorWeightDto>? sectorWeights;
  final List<IndustryWeightDto>? industryWeights;

  Map<String, dynamic> toJson() => _$SectorAllocationDtoToJson(this);
}

/// Sector weight data
@JsonSerializable()
class SectorWeightDto {
  const SectorWeightDto({
    this.sectorName,
    this.weightPercentage,
    this.marketCap,
    this.topStocks,
  });

  factory SectorWeightDto.fromJson(Map<String, dynamic> json) =>
      _$SectorWeightDtoFromJson(json);
  final String? sectorName;
  final double? weightPercentage;
  final double? marketCap;
  final List<String>? topStocks;

  Map<String, dynamic> toJson() => _$SectorWeightDtoToJson(this);
}

/// Industry weight data
@JsonSerializable()
class IndustryWeightDto {
  const IndustryWeightDto({
    this.industryName,
    this.parentSector,
    this.weightPercentage,
    this.marketCap,
    this.topStocks,
  });

  factory IndustryWeightDto.fromJson(Map<String, dynamic> json) =>
      _$IndustryWeightDtoFromJson(json);
  final String? industryName;
  final String? parentSector;
  final double? weightPercentage;
  final double? marketCap;
  final List<String>? topStocks;

  Map<String, dynamic> toJson() => _$IndustryWeightDtoToJson(this);
}

/// Market cap allocation data
@JsonSerializable()
class MarketCapAllocationDto {
  const MarketCapAllocationDto({this.segments});

  factory MarketCapAllocationDto.fromJson(Map<String, dynamic> json) =>
      _$MarketCapAllocationDtoFromJson(json);
  final List<MarketCapSegmentDto>? segments;

  Map<String, dynamic> toJson() => _$MarketCapAllocationDtoToJson(this);
}

/// Market cap segment data
@JsonSerializable()
class MarketCapSegmentDto {
  const MarketCapSegmentDto({
    this.segmentName,
    this.weightPercentage,
    this.segmentValue,
    this.numberOfStocks,
    this.topStocks,
  });

  factory MarketCapSegmentDto.fromJson(Map<String, dynamic> json) =>
      _$MarketCapSegmentDtoFromJson(json);
  final String? segmentName;
  final double? weightPercentage;
  final double? segmentValue;
  final int? numberOfStocks;
  final List<String>? topStocks;

  Map<String, dynamic> toJson() => _$MarketCapSegmentDtoToJson(this);
}
