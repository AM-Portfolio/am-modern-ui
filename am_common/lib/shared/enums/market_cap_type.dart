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
    }
  }
}
