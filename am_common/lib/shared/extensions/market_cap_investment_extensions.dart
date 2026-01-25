import '../enums/market_cap_type.dart';

/// Extensions for MarketCapType to provide investment-specific lists
extension MarketCapTypeInvestmentTypes on MarketCapType {
  /// All available market cap categories
  static List<MarketCapType> get allMarketCaps => MarketCapType.values;

  /// Market caps suitable for fund analysis
  static List<MarketCapType> get fundMarketCaps => [
    MarketCapType.all,
    MarketCapType.largeCap,
    MarketCapType.midCap,
    MarketCapType.smallCap,
  ];

  /// Market caps suitable for ETF analysis
  static List<MarketCapType> get etfMarketCaps => [
    MarketCapType.all,
    MarketCapType.largeCap,
    MarketCapType.midCap,
    MarketCapType.smallCap,
    MarketCapType.microCap,
  ];
}
