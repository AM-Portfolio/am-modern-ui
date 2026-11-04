import 'broker_holding_dto.dart';

/// API response model for portfolio holdings
/// This model directly maps to the API response structure
class PortfolioHoldingsDto {
  /// Constructor
  const PortfolioHoldingsDto({
    required this.equityHoldings,
    this.asOf,
    this.priceFreshness,
    this.priceSource,
    this.sessionDate,
  });

  /// Create from JSON response
  factory PortfolioHoldingsDto.fromJson(Map<String, dynamic> json) =>
      PortfolioHoldingsDto(
        equityHoldings: (json['equityHoldings'] as List? ?? [])
            .map((e) => EquityHoldingDto.fromJson(e as Map<String, dynamic>))
            .toList(),
        asOf: json['asOf'] as String?,
        priceFreshness: json['priceFreshness'] as String?,
        priceSource: json['priceSource'] as String?,
        sessionDate: json['sessionDate'] as String?,
      );

  /// List of equity holdings from API
  final List<EquityHoldingDto> equityHoldings;
  final String? asOf;
  final String? priceFreshness;
  final String? priceSource;
  final String? sessionDate;

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'equityHoldings': equityHoldings.map((e) => e.toJson()).toList(),
    if (asOf != null) 'asOf': asOf,
    if (priceFreshness != null) 'priceFreshness': priceFreshness,
    if (priceSource != null) 'priceSource': priceSource,
    if (sessionDate != null) 'sessionDate': sessionDate,
  };
}

/// API model for individual equity holding
class EquityHoldingDto {
  /// Constructor
  const EquityHoldingDto({
    required this.isin,
    required this.symbol,
    this.name = '',
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
    this.assetClass = 'EQUITY',
    this.hasInvestmentCost = false,
    this.hasGainLoss = false,
    this.hasTodayGainLoss = false,
  });

  /// Create from JSON response
  factory EquityHoldingDto.fromJson(Map<String, dynamic> json) =>
      EquityHoldingDto(
        isin: json['isin'] as String? ?? '',
        symbol: json['symbol'] as String? ?? '',
        name: json['name'] as String? ?? '',
        sector: json['sector'] as String? ?? '',
        industry: json['industry'] as String? ?? '',
        marketCap: json['marketCap'] as String? ?? '',
        quantity: _parseDouble(json['quantity']),
        investmentCost: _parseDoubleOrNull(json['investmentCost']) ?? 0.0,
        currentValue: _parseDouble(json['currentValue']),
        weightInPortfolio: _parseDouble(json['weightInPortfolio']),
        gainLoss: _parseDoubleOrNull(json['gainLoss']) ?? 0.0,
        gainLossPercentage: _parseDoubleOrNull(json['gainLossPercentage']) ?? 0.0,
        todayGainLoss: _parseDoubleOrNull(json['todayGainLoss']) ?? 0.0,
        todayGainLossPercentage:
            _parseDoubleOrNull(json['todayGainLossPercentage']) ?? 0.0,
        currentPrice: _parseDouble(json['currentPrice']),
        percentageChange: _parseDoubleOrNull(json['percentageChange']) ?? 0.0,
        hasInvestmentCost: json['investmentCost'] != null,
        hasGainLoss: json['gainLoss'] != null,
        hasTodayGainLoss: json['todayGainLoss'] != null,
        brokerPortfolios: json['brokerPortfolios'] is List
            ? (json['brokerPortfolios'] as List)
                  .map(
                    (e) => BrokerHoldingDto.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
            : [],
        assetClass: (json['assetClass'] as String?)?.trim().isNotEmpty == true
            ? (json['assetClass'] as String).trim().toUpperCase()
            : 'EQUITY',
      );

  /// Raw API fields - exact mapping to backend response
  final String isin;
  final String symbol;
  final String name;
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
  final String assetClass;
  final bool hasInvestmentCost;
  final bool hasGainLoss;
  final bool hasTodayGainLoss;

  /// Helper method to safely parse double values from API
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  static double? _parseDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'isin': isin,
    'symbol': symbol,
    'name': name,
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
    'assetClass': assetClass,
    'brokerPortfolios': brokerPortfolios.map((e) => e.toJson()).toList(),
  };
}
