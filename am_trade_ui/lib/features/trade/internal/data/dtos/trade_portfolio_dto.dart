import 'package:json_annotation/json_annotation.dart';

part 'trade_portfolio_dto.g.dart';

/// DTO for trade portfolio from API
/// API Response: { "portfolioId": "...", "name": "...", "metrics": { ... } }
@JsonSerializable()
class TradePortfolioDto {
  const TradePortfolioDto({
    required this.portfolioId,
    this.name,
    this.ownerId,
    this.totalValue,
    this.totalGainLoss,
    this.totalGainLossPercentage,
    this.holdingsCount,
    this.description,
    this.lastUpdated,
    // Trade metrics (from portfolio summary endpoint)
    this.totalTrades,
    this.netProfitLoss,
    this.netProfitLossPercentage,
    this.winRate,
    this.winningTrades,
    this.losingTrades,
    this.openPositions,
  });

  factory TradePortfolioDto.fromJson(Map<String, dynamic> json) {
    if (json['metrics'] != null && json['metrics'] is Map<String, dynamic>) {
      final metrics = json['metrics'] as Map<String, dynamic>;
      // Copy json to avoid modifying the original unmodifiable map
      final modifiedJson = Map<String, dynamic>.from(json);
      
      modifiedJson['totalTrades'] ??= metrics['totalTrades'];
      modifiedJson['netProfitLoss'] ??= metrics['netProfitLoss'];
      modifiedJson['netProfitLossPercentage'] ??= metrics['netProfitLossPercentage'];
      modifiedJson['winRate'] ??= metrics['winRate'];
      modifiedJson['winningTrades'] ??= metrics['winningTrades'];
      modifiedJson['losingTrades'] ??= metrics['losingTrades'];
      modifiedJson['openPositions'] ??= metrics['openPositions'];
      
      modifiedJson['totalValue'] ??= metrics['totalValue'];
      modifiedJson['totalGainLoss'] ??= metrics['netProfitLoss'];
      modifiedJson['totalGainLossPercentage'] ??= metrics['netProfitLossPercentage'];
      
      return _$TradePortfolioDtoFromJson(modifiedJson);
    }
    return _$TradePortfolioDtoFromJson(json);
  }

  final String portfolioId;
  final String? name;
  final String? ownerId;
  final double? totalValue;
  final double? totalGainLoss;
  final double? totalGainLossPercentage;
  final int? holdingsCount;
  final String? description;
  final String? lastUpdated;

  // Trade metrics (optional - from summary data)
  final int? totalTrades;
  final double? netProfitLoss;
  final double? netProfitLossPercentage;
  final double? winRate;
  final int? winningTrades;
  final int? losingTrades;
  final int? openPositions;

  Map<String, dynamic> toJson() => _$TradePortfolioDtoToJson(this);
}

/// DTO for trade portfolio list from API
@JsonSerializable()
class TradePortfolioListDto {
  const TradePortfolioListDto({required this.portfolios, this.totalCount});

  factory TradePortfolioListDto.fromJson(Map<String, dynamic> json) => _$TradePortfolioListDtoFromJson(json);

  final List<TradePortfolioDto> portfolios;
  final int? totalCount;

  Map<String, dynamic> toJson() => _$TradePortfolioListDtoToJson(this);
}
