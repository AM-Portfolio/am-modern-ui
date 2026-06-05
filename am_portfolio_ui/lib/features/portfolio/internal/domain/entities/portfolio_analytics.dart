/// Portfolio analytics response model
class PortfolioAnalytics {
  const PortfolioAnalytics({
    required this.portfolioId,
    required this.timestamp,
    required this.analytics,
  });
  final String portfolioId;
  final DateTime timestamp;
  final Analytics analytics;
}

/// Analytics data container
class Analytics {
  const Analytics({
    this.heatmap,
    this.movers,
    this.sectorAllocation,
    this.marketCapAllocation,
  });
  final Heatmap? heatmap;
  final Movers? movers;
  final SectorAllocation? sectorAllocation;
  final MarketCapAllocation? marketCapAllocation;
}

/// Heatmap data for sector performance visualization
class Heatmap {
  const Heatmap({required this.sectors});
  final List<Sector> sectors;
}

/// Sector performance data
class Sector {
  const Sector({
    required this.sectorName,
    required this.performanceRank,
    required this.performance,
    required this.changePercent,
    required this.weightage,
    required this.color,
    required this.stockCount,
    required this.totalValue,
    required this.totalReturnAmount,
    required this.stocks,
  });
  final String sectorName;
  final int performanceRank;
  final double performance;
  final double changePercent;
  final double weightage;
  final String color;
  final int stockCount;
  final double totalValue;
  final double totalReturnAmount;
  final List<Stock> stocks;

  /// Helper getter for formatted performance
  String get formattedPerformance => '${performance.toStringAsFixed(2)}%';

  /// Helper getter for formatted change percent
  String get formattedChangePercent =>
      '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%';

  /// Helper getter for formatted weightage
  String get formattedWeightage => '${weightage.toStringAsFixed(2)}%';

  /// Helper getter to check if sector is performing positively
  bool get isPositive => performance >= 0;
}

/// Stock data in portfolio
class Stock {
  // Weight percentage in portfolio/sector

  const Stock({
    required this.symbol,
    required this.companyName,
    required this.lastPrice,
    required this.changeAmount,
    required this.changePercent,
    required this.sector,
    this.quantity,
    this.avgPrice,
    this.marketValue,
    this.totalReturn,
    this.weight,
  });
  final String symbol;
  final String companyName;
  final double lastPrice;
  final double changeAmount;
  final double changePercent;
  final String sector;
  final double? quantity;
  final double? avgPrice;
  final double? marketValue;
  final double? totalReturn;
  final double? weight;

  /// Helper getter for formatted change percent
  String get formattedChangePercent =>
      '${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(2)}%';

  /// Helper getter for formatted change amount
  String get formattedChangeAmount => '₹${changeAmount.toStringAsFixed(2)}';

  /// Helper getter for formatted last price
  String get formattedLastPrice => '₹${lastPrice.toStringAsFixed(2)}';

  /// Helper getter to check if stock is gaining
  bool get isGainer => changePercent > 0;

  /// Create a copy of this Stock with the given fields replaced
  Stock copyWith({
    String? symbol,
    String? companyName,
    double? lastPrice,
    double? changeAmount,
    double? changePercent,
    String? sector,
    double? quantity,
    double? avgPrice,
    double? marketValue,
    double? totalReturn,
    double? weight,
  }) {
    return Stock(
      symbol: symbol ?? this.symbol,
      companyName: companyName ?? this.companyName,
      lastPrice: lastPrice ?? this.lastPrice,
      changeAmount: changeAmount ?? this.changeAmount,
      changePercent: changePercent ?? this.changePercent,
      sector: sector ?? this.sector,
      quantity: quantity ?? this.quantity,
      avgPrice: avgPrice ?? this.avgPrice,
      marketValue: marketValue ?? this.marketValue,
      totalReturn: totalReturn ?? this.totalReturn,
      weight: weight ?? this.weight,
    );
  }
}

/// Top movers (gainers and losers)
class Movers {
  const Movers({required this.topGainers, required this.topLosers});
  final List<Stock> topGainers;
  final List<Stock> topLosers;
}

/// Sector allocation breakdown
class SectorAllocation {
  const SectorAllocation({
    required this.sectorWeights,
    required this.industryWeights,
  });
  final List<SectorWeight> sectorWeights;
  final List<IndustryWeight> industryWeights;
}

/// Sector weight information
class SectorWeight {
  const SectorWeight({
    required this.sectorName,
    required this.weightPercentage,
    required this.marketCap,
    required this.topStocks,
  });
  final String sectorName;
  final double weightPercentage;
  final double marketCap;
  final List<String> topStocks;

  /// Helper getter for formatted weight percentage
  String get formattedWeightPercentage =>
      '${weightPercentage.toStringAsFixed(2)}%';

  /// Helper getter for formatted market cap
  String get formattedMarketCap => '₹${marketCap.toStringAsFixed(0)}';
}

/// Industry weight information
class IndustryWeight {
  const IndustryWeight({
    required this.industryName,
    required this.parentSector,
    required this.weightPercentage,
    required this.marketCap,
    required this.topStocks,
  });
  final String industryName;
  final String parentSector;
  final double weightPercentage;
  final double marketCap;
  final List<String> topStocks;

  /// Helper getter for formatted weight percentage
  String get formattedWeightPercentage =>
      '${weightPercentage.toStringAsFixed(2)}%';

  /// Helper getter for formatted market cap
  String get formattedMarketCap => '₹${marketCap.toStringAsFixed(0)}';
}

/// Market cap allocation breakdown
class MarketCapAllocation {
  const MarketCapAllocation({required this.segments});
  final List<MarketCapSegment> segments;
}

/// Market cap segment information
class MarketCapSegment {
  const MarketCapSegment({
    required this.segmentName,
    required this.weightPercentage,
    required this.segmentValue,
    required this.numberOfStocks,
    required this.topStocks,
  });
  final String segmentName;
  final double weightPercentage;
  final double segmentValue;
  final int numberOfStocks;
  final List<String> topStocks;

  /// Helper getter for formatted weight percentage
  String get formattedWeightPercentage =>
      '${weightPercentage.toStringAsFixed(2)}%';

  /// Helper getter for formatted segment value
  String get formattedSegmentValue => '₹${segmentValue.toStringAsFixed(0)}';
}
