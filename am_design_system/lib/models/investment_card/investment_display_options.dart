/// Display options for investment card features
class InvestmentDisplayOptions {
  const InvestmentDisplayOptions({
    this.showInvestmentDetails = true,
    this.showCurrentPrice = true,
    this.showQuantity = true,
    this.showAveragePrice = true,
    this.showChangeValue = true,
    this.showChangePercent = true,
    this.showPerformanceSection = true,
    this.showDefaultValue = true,
    this.showAdditionalInfo = true,
  });
  final bool showInvestmentDetails;
  final bool showCurrentPrice;
  final bool showQuantity;
  final bool showAveragePrice;
  final bool showChangeValue;
  final bool showChangePercent;
  final bool showPerformanceSection;
  final bool showDefaultValue;
  final bool showAdditionalInfo;

  /// Default options showing all details
  static const InvestmentDisplayOptions full = InvestmentDisplayOptions();

  /// Minimal options for compact displays
  static const InvestmentDisplayOptions minimal = InvestmentDisplayOptions(
    showInvestmentDetails: false,
    showCurrentPrice: false,
    showQuantity: false,
    showAveragePrice: false,
    showChangeValue: false,
    showChangePercent: false,
    showPerformanceSection: false,
    showAdditionalInfo: false,
  );

  /// Watchlist options showing basic info
  static const InvestmentDisplayOptions watchlist = InvestmentDisplayOptions(
    showInvestmentDetails: false,
    showCurrentPrice: false,
  );

  /// Clean options for sector stock display
  static const InvestmentDisplayOptions sectorStock = InvestmentDisplayOptions(
    showInvestmentDetails: false,
    showCurrentPrice: false,
    showQuantity: false,
    showAveragePrice: false,
    showChangeValue: false,
    showChangePercent: false,
    showPerformanceSection: false,
    showDefaultValue: false,
    showAdditionalInfo: false,
  );

  /// Create a copy with modified values
  InvestmentDisplayOptions copyWith({
    bool? showInvestmentDetails,
    bool? showCurrentPrice,
    bool? showQuantity,
    bool? showAveragePrice,
    bool? showChangeValue,
    bool? showChangePercent,
    bool? showPerformanceSection,
    bool? showDefaultValue,
    bool? showAdditionalInfo,
  }) => InvestmentDisplayOptions(
    showInvestmentDetails: showInvestmentDetails ?? this.showInvestmentDetails,
    showCurrentPrice: showCurrentPrice ?? this.showCurrentPrice,
    showQuantity: showQuantity ?? this.showQuantity,
    showAveragePrice: showAveragePrice ?? this.showAveragePrice,
    showChangeValue: showChangeValue ?? this.showChangeValue,
    showChangePercent: showChangePercent ?? this.showChangePercent,
    showPerformanceSection:
        showPerformanceSection ?? this.showPerformanceSection,
    showDefaultValue: showDefaultValue ?? this.showDefaultValue,
    showAdditionalInfo: showAdditionalInfo ?? this.showAdditionalInfo,
  );
}
