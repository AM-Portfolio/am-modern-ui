/// Economic sectors for investment categorization
enum SectorType {
  /// All sectors
  all,
  
  /// Technology sector
  technology,
  
  /// Healthcare sector
  healthcare,
  
  /// Financial Services
  finance,
  
  /// Energy sector
  energy,
  
  /// Consumer sector
  consumer,
  
  /// Industrials
  industrials,
  
  /// Utilities
  utilities,
  
  /// Information Technology
  it,
  
  /// Consumer Goods (FMCG)
  fmcg,
  
  /// Telecommunications
  telecom,
  
  /// Real Estate
  realEstate,
  
  /// Materials
  materials,
  
  /// Consumer Services
  consumerServices,
  
  /// Automobiles
  automobiles,
  
  /// Pharmaceuticals
  pharma,
  
  /// Infrastructure
  infrastructure,
  
  /// Banking
  banking,
  
  /// Manufacturing
  manufacturing,
  
  /// Agriculture
  agriculture,
  
  /// Metals & Mining
  metals,
  
  /// Other sectors
  other,
}

/// Extension methods for SectorType
extension SectorTypeExtension on SectorType {
  /// Get display name for the sector type
  String get displayName {
    switch (this) {
      case SectorType.all:
        return 'All Sectors';
      case SectorType.technology:
        return 'Technology';
      case SectorType.healthcare:
        return 'Healthcare';
      case SectorType.finance:
        return 'Financial Services';
      case SectorType.energy:
        return 'Energy';
      case SectorType.consumer:
        return 'Consumer';
      case SectorType.industrials:
        return 'Industrials';
      case SectorType.utilities:
        return 'Utilities';
      case SectorType.it:
        return 'Information Technology';
      case SectorType.fmcg:
        return 'Consumer Goods (FMCG)';
      case SectorType.telecom:
        return 'Telecommunications';
      case SectorType.realEstate:
        return 'Real Estate';
      case SectorType.materials:
        return 'Materials';
      case SectorType.consumerServices:
        return 'Consumer Services';
      case SectorType.automobiles:
        return 'Automobiles';
      case SectorType.pharma:
        return 'Pharmaceuticals';
      case SectorType.infrastructure:
        return 'Infrastructure';
      case SectorType.banking:
        return 'Banking';
      case SectorType.manufacturing:
        return 'Manufacturing';
      case SectorType.agriculture:
        return 'Agriculture';
      case SectorType.metals:
        return 'Metals & Mining';
      case SectorType.other:
        return 'Other';
    }
  }
}
