import 'broker_holding_dto.dart';

/// API response model for portfolio summary.
/// Fields are exact matches to the Java backend PortfolioSummaryV1 + BasePortfolioSummay models.
class PortfolioSummaryDto {
  const PortfolioSummaryDto({
    required this.currentValue,
    required this.investmentValue,
    required this.totalGainLoss,
    required this.totalGainLossPercentage,
    required this.todayGainLoss,
    required this.todayGainLossPercentage,
    required this.totalAssets,
    required this.gainersCount,
    required this.losersCount,
    required this.todayGainersCount,
    required this.todayLosersCount,
    required this.marketCapHoldings,
    required this.sectorialHoldings,
    required this.brokerPortfolios,
  });

  /// Create from JSON response — keys match exact backend field names.
  factory PortfolioSummaryDto.fromJson(Map<String, dynamic> json) {
    try {
      return PortfolioSummaryDto(
        currentValue: _parseDouble(json['currentValue']),
        investmentValue: _parseDouble(json['investmentValue']),
        totalGainLoss: _parseDouble(json['totalGainLoss']),
        totalGainLossPercentage: _parseDouble(json['totalGainLossPercentage']),
        todayGainLoss: _parseDouble(json['todayGainLoss']),
        todayGainLossPercentage: _parseDouble(json['todayGainLossPercentage']),
        totalAssets: _parseInt(json['totalAssets']),
        gainersCount: _parseInt(json['gainersCount']),
        losersCount: _parseInt(json['losersCount']),
        todayGainersCount: _parseInt(json['todayGainersCount']),
        todayLosersCount: _parseInt(json['todayLosersCount']),
        marketCapHoldings: _parseEquityHoldingsMap(json['marketCapHoldings']),
        sectorialHoldings: _parseEquityHoldingsMap(json['sectorialHoldings']),
        brokerPortfolios: _parseBrokerPortfolios(json['brokerPortfolios']),
      );
    } catch (e) {
      // ignore: avoid_print
      print('Error parsing PortfolioSummaryDto: $e');
      rethrow;
    }
  }

  // Raw API fields — exact mapping to backend
  final double currentValue;
  final double investmentValue;
  final double totalGainLoss;
  final double totalGainLossPercentage;
  final double todayGainLoss;
  final double todayGainLossPercentage;
  final int totalAssets;
  final int gainersCount;
  final int losersCount;
  final int todayGainersCount;
  final int todayLosersCount;

  /// marketCapHoldings: Map<String (cap category), List<EquityHolding>>
  final Map<String, List<SectorialEquityHoldingDto>> marketCapHoldings;

  /// sectorialHoldings: Map<String (sector name), List<EquityHolding>>
  final Map<String, List<SectorialEquityHoldingDto>> sectorialHoldings;

  /// brokerPortfolios: Map<String (BrokerType), BrokerPortfolioSummary>
  final Map<String, dynamic> brokerPortfolios;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Parses Map<String, List<EquityHoldings>> from backend JSON.
  static Map<String, List<SectorialEquityHoldingDto>> _parseEquityHoldingsMap(
    dynamic value,
  ) {
    if (value == null || value is! Map) return {};
    final result = <String, List<SectorialEquityHoldingDto>>{};
    (value as Map<String, dynamic>).forEach((key, listVal) {
      if (listVal is List) {
        result[key] = listVal
            .map(
              (item) => SectorialEquityHoldingDto.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      }
    });
    return result;
  }

  static Map<String, dynamic> _parseBrokerPortfolios(dynamic value) {
    if (value == null || value is! Map) return {};
    return Map<String, dynamic>.from(value as Map);
  }

  Map<String, dynamic> toJson() => {
    'currentValue': currentValue,
    'investmentValue': investmentValue,
    'totalGainLoss': totalGainLoss,
    'totalGainLossPercentage': totalGainLossPercentage,
    'todayGainLoss': todayGainLoss,
    'todayGainLossPercentage': todayGainLossPercentage,
    'totalAssets': totalAssets,
    'gainersCount': gainersCount,
    'losersCount': losersCount,
    'todayGainersCount': todayGainersCount,
    'todayLosersCount': todayLosersCount,
  };
}

/// Represents an equity holding inside sectorialHoldings or marketCapHoldings.
/// Maps to the Java EquityHoldings model.
class SectorialEquityHoldingDto {
  const SectorialEquityHoldingDto({
    required this.isin,
    required this.symbol,
    this.name = '',
    required this.sector,
    required this.industry,
    required this.marketCap,
    required this.portfolioId,
    required this.portfolioName,
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

  factory SectorialEquityHoldingDto.fromJson(Map<String, dynamic> json) =>
      SectorialEquityHoldingDto(
        isin: json['isin'] as String? ?? '',
        symbol: json['symbol'] as String? ?? '',
        name: json['name'] as String? ?? '',
        sector: json['sector'] as String? ?? '',
        industry: json['industry'] as String? ?? '',
        marketCap: json['marketCap'] as String? ?? '',
        portfolioId: json['portfolioId'] as String? ?? '',
        portfolioName: json['portfolioName'] as String? ?? '',
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
            .map((b) => BrokerHoldingDto.fromJson(b as Map<String, dynamic>))
            .toList(),
      );

  final String isin;
  final String symbol;
  final String name;
  final String sector;
  final String industry;
  final String marketCap;
  final String portfolioId;
  final String portfolioName;
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

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
