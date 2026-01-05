import 'package:json_annotation/json_annotation.dart';

part 'trade_summary_dto.g.dart';

/// DTO for trade sector allocation from API
@JsonSerializable()
class TradeSectorAllocationDto {
  const TradeSectorAllocationDto({
    required this.sector,
    required this.value,
    required this.percentage,
    this.holdingsCount,
  });

  factory TradeSectorAllocationDto.fromJson(Map<String, dynamic> json) =>
      _$TradeSectorAllocationDtoFromJson(json);

  final String sector;
  final double value;
  final double percentage;
  final int? holdingsCount;

  Map<String, dynamic> toJson() => _$TradeSectorAllocationDtoToJson(this);
}

/// DTO for trade top mover from API
@JsonSerializable()
class TradeTopMoverDto {
  const TradeTopMoverDto({
    required this.symbol,
    required this.name,
    required this.change,
    required this.changePercentage,
    required this.currentPrice,
  });

  factory TradeTopMoverDto.fromJson(Map<String, dynamic> json) =>
      _$TradeTopMoverDtoFromJson(json);

  final String symbol;
  final String name;
  final double change;
  final double changePercentage;
  final double currentPrice;

  Map<String, dynamic> toJson() => _$TradeTopMoverDtoToJson(this);
}

/// DTO for trade summary from API
@JsonSerializable()
class TradeSummaryDto {
  const TradeSummaryDto({
    required this.totalValue,
    required this.totalInvested,
    required this.totalGainLoss,
    required this.totalGainLossPercentage,
    required this.todayChange,
    required this.todayChangePercentage,
    this.sectorAllocation,
    this.topGainers,
    this.topLosers,
    this.holdingsCount,
  });

  factory TradeSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$TradeSummaryDtoFromJson(json);

  final double totalValue;
  final double totalInvested;
  final double totalGainLoss;
  final double totalGainLossPercentage;
  final double todayChange;
  final double todayChangePercentage;
  final List<TradeSectorAllocationDto>? sectorAllocation;
  final List<TradeTopMoverDto>? topGainers;
  final List<TradeTopMoverDto>? topLosers;
  final int? holdingsCount;

  Map<String, dynamic> toJson() => _$TradeSummaryDtoToJson(this);
}
