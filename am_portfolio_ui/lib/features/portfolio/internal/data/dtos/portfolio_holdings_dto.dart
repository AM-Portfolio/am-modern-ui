import 'broker_holding_dto.dart';

/// API response model for portfolio holdings
/// This model directly maps to the API response structure
class PortfolioHoldingsDto {
  /// Constructor
  const PortfolioHoldingsDto({required this.equityHoldings});

  /// Create from JSON response
  factory PortfolioHoldingsDto.fromJson(Map<String, dynamic> json) =>
      PortfolioHoldingsDto(
        equityHoldings: (json['equityHoldings'] as List? ?? [])
            .map((e) => EquityHoldingDto.fromJson(e))
            .toList(),
      );

  /// List of equity holdings from API
  final List<EquityHoldingDto> equityHoldings;

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'equityHoldings': equityHoldings.map((e) => e.toJson()).toList(),
  };
}

/// API model for individual equity holding
class EquityHoldingDto {
  /// Constructor
  const EquityHoldingDto({
    required this.isin,
    required this.symbol,
    required this.sector,
    required this.industry,
    required this.marketCap,
    required this.quantity,
    required this.investmentCost,
    required this.currentValue,
    required this.weightInPortfolio,
    required this.gainLoss,
    required this.gainLossPercentage,
    required this.todayGainLoss,
    required this.todayGainLossPercentage,
    required this.currentPrice,
    required this.percentageChange,
    required this.brokerPortfolios,
  });

  /// Create from JSON response
  factory EquityHoldingDto.fromJson(Map<String, dynamic> json) =>
      EquityHoldingDto(
        isin: json['isin'] as String? ?? '',
        symbol: json['symbol'] as String? ?? '',
        sector: json['sector'] as String? ?? '',
        industry: json['industry'] as String? ?? '',
        marketCap: json['marketCap'] as String? ?? '',
        quantity: _parseDouble(json['quantity']),
        investmentCost: _parseDouble(json['investmentCost']),
        currentValue: _parseDouble(json['currentValue']),
        weightInPortfolio: _parseDouble(json['weightInPortfolio']),
        gainLoss: _parseDouble(json['gainLoss']),
        gainLossPercentage: _parseDouble(json['gainLossPercentage']),
        todayGainLoss: _parseDouble(json['todayGainLoss']),
        todayGainLossPercentage: _parseDouble(json['todayGainLossPercentage']),
        currentPrice: _parseDouble(json['currentPrice']),
        percentageChange: _parseDouble(json['percentageChange']),
        brokerPortfolios: (json['brokerPortfolios'] as List? ?? [])
            .map((e) => BrokerHoldingDto.fromJson(e))
            .toList(),
      );

  /// Raw API fields - exact mapping to backend response
  final String isin;
  final String symbol;
  final String sector;
  final String industry;
  final String marketCap;
  final double quantity;
  final double investmentCost;
  final double currentValue;
  final double weightInPortfolio;
  final double gainLoss;
  final double gainLossPercentage;
  final double todayGainLoss;
  final double todayGainLossPercentage;
  final double currentPrice;
  final double percentageChange;
  final List<BrokerHoldingDto> brokerPortfolios;

  /// Helper method to safely parse double values from API
  static double _parseDouble(value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return 0.0;
      }
    }
    return 0.0;
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'isin': isin,
    'symbol': symbol,
    'sector': sector,
    'industry': industry,
    'marketCap': marketCap,
    'quantity': quantity,
    'investmentCost': investmentCost,
    'currentValue': currentValue,
    'weightInPortfolio': weightInPortfolio,
    'gainLoss': gainLoss,
    'gainLossPercentage': gainLossPercentage,
    'todayGainLoss': todayGainLoss,
    'todayGainLossPercentage': todayGainLossPercentage,
    'currentPrice': currentPrice,
    'percentageChange': percentageChange,
    'brokerPortfolios': brokerPortfolios.map((e) => e.toJson()).toList(),
  };
}
