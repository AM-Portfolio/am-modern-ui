import '../widgets/selectors/selectors.dart';

/// Extensions for SectorType to provide investment-specific lists
extension SectorTypeInvestmentTypes on SectorType {
  /// All available sectors
  static List<SectorType> get allSectors => SectorType.values;

  /// Sectors suitable for fund analysis
  static List<SectorType> get fundSectors => [
    SectorType.all,
    SectorType.technology,
    SectorType.healthcare,
    SectorType.finance,
    SectorType.energy,
    SectorType.consumer,
  ];

  /// Sectors suitable for ETF analysis
  static List<SectorType> get etfSectors => [
    SectorType.all,
    SectorType.technology,
    SectorType.healthcare,
    SectorType.finance,
    SectorType.energy,
    SectorType.consumer,
    SectorType.industrials,
    SectorType.utilities,
  ];
}
