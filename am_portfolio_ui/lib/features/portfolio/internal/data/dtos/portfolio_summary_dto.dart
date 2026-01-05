import 'broker_holding_dto.dart';

/// API response model for portfolio summary
/// This model directly maps to the API response structure
class PortfolioSummaryDto {
  /// Constructor
  const PortfolioSummaryDto({
    required this.totalValue,
    required this.investmentValue,
    required this.todaysGain,
    required this.totalGain,
    required this.totalGainPercentage,
    required this.todaysGainPercentage,
    required this.todayGainLossPercentage,
    required this.totalAssets,
    required this.todayGainersCount,
    required this.todayLosersCount,
    required this.gainersCount,
    required this.losersCount,
    required this.marketCapHoldings,
    required this.sectorAllocation,
    required this.topPerformers,
    required this.topLosers,
  });

  /// Create from JSON response
  factory PortfolioSummaryDto.fromJson(Map<String, dynamic> json) {
    // Debug logging to see raw API response
    return PortfolioSummaryDto(
      totalValue: _parseDouble(json['currentValue']),
      investmentValue: _parseDouble(json['investmentValue']),
      todaysGain: _parseDouble(json['todayGainLoss']),
      totalGain: _parseDouble(json['totalGainLoss']),
      totalGainPercentage: _parseDouble(json['totalGainLossPercentage']),
      todaysGainPercentage: _parseDouble(json['todayGainLossPercentage']),
      todayGainLossPercentage: _parseDouble(json['todayGainLossPercentage']),
      totalAssets: _parseInt(json['totalAssets']),
      todayGainersCount: _parseInt(json['todayGainersCount']),
      todayLosersCount: _parseInt(json['todayLosersCount']),
      gainersCount: _parseInt(json['gainersCount']),
      losersCount: _parseInt(json['losersCount']),
      marketCapHoldings: _parseMarketCapHoldings(json['marketCapHoldings']),
      sectorAllocation: _parseSectorAllocation(json['sectorAllocation']),
      topPerformers: _parseTopPerformers(json['topPerformers']),
      topLosers: _parseTopLosers(json['topLosers']),
    );
  }

  /// Raw API fields - exact mapping to backend response
  final double totalValue;
  final double investmentValue;
  final double todaysGain;
  final double totalGain;
  final double totalGainPercentage;
  final double todaysGainPercentage;
  final double todayGainLossPercentage;
  final int totalAssets;
  final int todayGainersCount;
  final int todayLosersCount;
  final int gainersCount;
  final int losersCount;
  final Map<String, List<MarketCapHoldingDto>> marketCapHoldings;
  final Map<String, double> sectorAllocation;
  final List<ApiTopPerformer> topPerformers;
  final List<ApiTopLoser> topLosers;

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

  /// Helper method to safely parse int values from API
  static int _parseInt(value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {
        return 0;
      }
    }
    return 0;
  }

  /// Parse market cap holdings
  static Map<String, List<MarketCapHoldingDto>> _parseMarketCapHoldings(value) {
    if (value == null) return {};

    final result = <String, List<MarketCapHoldingDto>>{};
    final map = value as Map<String, dynamic>;

    for (final entry in map.entries) {
      final holdings = (entry.value as List? ?? [])
          .map((h) => MarketCapHoldingDto.fromJson(h))
          .toList();
      result[entry.key] = holdings;
    }

    return result;
  }

  /// Parse sector allocation
  static Map<String, double> _parseSectorAllocation(value) {
    if (value == null) return {};

    final result = <String, double>{};
    final map = value as Map<String, dynamic>;

    for (final entry in map.entries) {
      result[entry.key] = _parseDouble(entry.value);
    }

    return result;
  }

  /// Parse top performers
  static List<ApiTopPerformer> _parseTopPerformers(value) {
    if (value == null) return [];
    return (value as List).map((p) => ApiTopPerformer.fromJson(p)).toList();
  }

  /// Parse top losers
  static List<ApiTopLoser> _parseTopLosers(value) {
    if (value == null) return [];
    return (value as List).map((l) => ApiTopLoser.fromJson(l)).toList();
  }

  /// Convert to JSON for API requests
  Map<String, dynamic> toJson() => {
    'totalValue': totalValue,
    'investmentValue': investmentValue,
    'todaysGain': todaysGain,
    'totalGain': totalGain,
    'totalGainPercentage': totalGainPercentage,
    'todaysGainPercentage': todaysGainPercentage,
    'todayGainLossPercentage': todayGainLossPercentage,
    'totalAssets': totalAssets,
    'todayGainersCount': todayGainersCount,
    'todayLosersCount': todayLosersCount,
    'gainersCount': gainersCount,
    'losersCount': losersCount,
    'marketCapHoldings': marketCapHoldings.map(
      (key, value) => MapEntry(key, value.map((h) => h.toJson()).toList()),
    ),
    'sectorAllocation': sectorAllocation,
    'topPerformers': topPerformers.map((p) => p.toJson()).toList(),
    'topLosers': topLosers.map((l) => l.toJson()).toList(),
  };
}

/// API model for market cap holding
class MarketCapHoldingDto {
  const MarketCapHoldingDto({
    required this.isin,
    required this.symbol,
    required this.sector,
    required this.industry,
    required this.marketCap,
    required this.quantity,
    required this.investmentCost,
    required this.brokerPortfolios,
  });

  factory MarketCapHoldingDto.fromJson(Map<String, dynamic> json) =>
      MarketCapHoldingDto(
        isin: json['isin'] as String? ?? '',
        symbol: json['symbol'] as String? ?? '',
        sector: json['sector'] as String? ?? '',
        industry: json['industry'] as String? ?? '',
        marketCap: json['marketCap'] as String? ?? '',
        quantity: PortfolioSummaryDto._parseDouble(json['quantity']),
        investmentCost: PortfolioSummaryDto._parseDouble(
          json['investmentCost'],
        ),
        brokerPortfolios: (json['brokerPortfolios'] as List? ?? [])
            .map((b) => BrokerHoldingDto.fromJson(b))
            .toList(),
      );
  final String isin;
  final String symbol;
  final String sector;
  final String industry;
  final String marketCap;
  final double quantity;
  final double investmentCost;
  final List<BrokerHoldingDto> brokerPortfolios;

  Map<String, dynamic> toJson() => {
    'isin': isin,
    'symbol': symbol,
    'sector': sector,
    'industry': industry,
    'marketCap': marketCap,
    'quantity': quantity,
    'investmentCost': investmentCost,
    'brokerPortfolios': brokerPortfolios.map((b) => b.toJson()).toList(),
  };
}

/// API model for top performer
class ApiTopPerformer {
  const ApiTopPerformer({
    required this.symbol,
    required this.gainPercentage,
    required this.gainAmount,
  });

  factory ApiTopPerformer.fromJson(Map<String, dynamic> json) =>
      ApiTopPerformer(
        symbol: json['symbol'] as String? ?? '',
        gainPercentage: PortfolioSummaryDto._parseDouble(
          json['gainPercentage'],
        ),
        gainAmount: PortfolioSummaryDto._parseDouble(json['gainAmount']),
      );
  final String symbol;
  final double gainPercentage;
  final double gainAmount;

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'gainPercentage': gainPercentage,
    'gainAmount': gainAmount,
  };
}

/// API model for top loser
class ApiTopLoser {
  const ApiTopLoser({
    required this.symbol,
    required this.lossPercentage,
    required this.lossAmount,
  });

  factory ApiTopLoser.fromJson(Map<String, dynamic> json) => ApiTopLoser(
    symbol: json['symbol'] as String? ?? '',
    lossPercentage: PortfolioSummaryDto._parseDouble(json['lossPercentage']),
    lossAmount: PortfolioSummaryDto._parseDouble(json['lossAmount']),
  );
  final String symbol;
  final double lossPercentage;
  final double lossAmount;

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'lossPercentage': lossPercentage,
    'lossAmount': lossAmount,
  };
}
