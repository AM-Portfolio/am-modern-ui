/// Market capitalization categories for investment analysis
enum MarketCapType {
  /// All market cap sizes
  all,
  
  /// Large cap companies (typically > ₹20,000 Cr)
  largeCap,
  
  /// Mid cap companies (typically ₹5,000 Cr - ₹20,000 Cr)
  midCap,
  
  /// Small cap companies (typically < ₹5,000 Cr)
  smallCap,
  
  /// Micro cap companies (very small market capitalization)
  microCap,

  /// Mega cap companies (extremely large market capitalization)
  megaCap;

  // ── Static list getters (used by selector widgets) ───────────────────────

  static List<MarketCapType> get allMarketCaps => MarketCapType.values;

  static List<MarketCapType> get portfolioMarketCaps => const [
        MarketCapType.all,
        MarketCapType.largeCap,
        MarketCapType.midCap,
        MarketCapType.smallCap,
      ];

  static List<MarketCapType> get standardMarketCaps => const [
        MarketCapType.largeCap,
        MarketCapType.midCap,
        MarketCapType.smallCap,
        MarketCapType.microCap,
      ];

  static List<MarketCapType> get webMarketCaps => MarketCapType.values;
}

/// Extension methods for MarketCapType
extension MarketCapTypeExtension on MarketCapType {
  /// Get display name for the market cap type
  String get displayName {
    switch (this) {
      case MarketCapType.all:
        return 'All Cap';
      case MarketCapType.largeCap:
        return 'Large Cap';
      case MarketCapType.midCap:
        return 'Mid Cap';
      case MarketCapType.smallCap:
        return 'Small Cap';
      case MarketCapType.microCap:
        return 'Micro Cap';
      case MarketCapType.megaCap:
        return 'Mega Cap';
    }
  }

  /// Short name for compact display
  String get shortName {
    switch (this) {
      case MarketCapType.all:
        return 'All';
      case MarketCapType.largeCap:
        return 'Large';
      case MarketCapType.midCap:
        return 'Mid';
      case MarketCapType.smallCap:
        return 'Small';
      case MarketCapType.microCap:
        return 'Micro';
      case MarketCapType.megaCap:
        return 'Mega';
    }
  }
  // icon getter is defined in am_design_system's MarketCapTypeUIExtension (UI layer)
}

