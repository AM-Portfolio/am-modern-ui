class BasketOpportunity {
  final String etfIsin;
  final String etfName;
  final double matchScore;
  final double replicaScore;
  final bool readyToReplicate;
  final int totalItems;
  final int heldCount;
  final int missingCount;
  final double? heldMatchScore;
  final double? substituteMatchScore;
  final double? missingMatchScore;
  final double? remainingPortfolioValue;
  final double? investmentAmount;
  final double? totalPortfolioValue;
  final double? minimumInvestmentAmount;
  final double? actualInvestmentCost;
  final double? budgetVariance;
  final double? residualCash;
  final double? budgetUtilization;
  final double? heldCoverageValue;
  final List<String> excludedSymbols;
  final bool? sectorialBasket;
  final String? dominantSector;
  final List<String> etfConstituentIsins;
  final int? appliedSubstituteCount;
  final List<String> substituteWarnings;
  final List<BasketItem> composition;
  final List<BasketItem> buyList;

  const BasketOpportunity({
    required this.etfIsin,
    required this.etfName,
    this.matchScore = 0.0,
    this.replicaScore = 0.0,
    this.readyToReplicate = false,
    this.totalItems = 0,
    this.heldCount = 0,
    this.missingCount = 0,
    this.heldMatchScore,
    this.substituteMatchScore,
    this.missingMatchScore,
    this.remainingPortfolioValue,
    this.investmentAmount,
    this.totalPortfolioValue,
    this.minimumInvestmentAmount,
    this.actualInvestmentCost,
    this.budgetVariance,
    this.residualCash,
    this.budgetUtilization,
    this.heldCoverageValue,
    this.excludedSymbols = const [],
    this.sectorialBasket,
    this.dominantSector,
    this.etfConstituentIsins = const [],
    this.appliedSubstituteCount,
    this.substituteWarnings = const [],
    this.composition = const [],
    this.buyList = const [],
  });

  factory BasketOpportunity.fromJson(Map<String, dynamic> json) {
    return BasketOpportunity(
      etfIsin: json['etfIsin'] as String,
      etfName: json['etfName'] as String,
      matchScore: (json['matchScore'] as num?)?.toDouble() ?? 0.0,
      replicaScore: (json['replicaScore'] as num?)?.toDouble() ?? 0.0,
      readyToReplicate: json['readyToReplicate'] as bool? ?? false,
      totalItems: json['totalItems'] as int? ?? 0,
      heldCount: json['heldCount'] as int? ?? 0,
      missingCount: json['missingCount'] as int? ?? 0,
      heldMatchScore: (json['heldMatchScore'] as num?)?.toDouble(),
      substituteMatchScore: (json['substituteMatchScore'] as num?)?.toDouble(),
      missingMatchScore: (json['missingMatchScore'] as num?)?.toDouble(),
      remainingPortfolioValue: (json['remainingPortfolioValue'] as num?)?.toDouble(),
      investmentAmount: (json['investmentAmount'] as num?)?.toDouble(),
      totalPortfolioValue: (json['totalPortfolioValue'] as num?)?.toDouble(),
      minimumInvestmentAmount: (json['minimumInvestmentAmount'] as num?)?.toDouble(),
      actualInvestmentCost: (json['actualInvestmentCost'] as num?)?.toDouble(),
      budgetVariance: (json['budgetVariance'] as num?)?.toDouble(),
      residualCash: (json['residualCash'] as num?)?.toDouble(),
      budgetUtilization: (json['budgetUtilization'] as num?)?.toDouble(),
      heldCoverageValue: (json['heldCoverageValue'] as num?)?.toDouble(),
      excludedSymbols: (json['excludedSymbols'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      sectorialBasket: json['sectorialBasket'] as bool?,
      dominantSector: json['dominantSector'] as String?,
      etfConstituentIsins: (json['etfConstituentIsins'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      appliedSubstituteCount: json['appliedSubstituteCount'] as int?,
      substituteWarnings: (json['substituteWarnings'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      composition: (json['composition'] as List<dynamic>?)
              ?.map((e) => BasketItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      buyList: (json['buyList'] as List<dynamic>?)
              ?.map((e) => BasketItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'etfIsin': etfIsin,
      'etfName': etfName,
      'matchScore': matchScore,
      'replicaScore': replicaScore,
      'readyToReplicate': readyToReplicate,
      'totalItems': totalItems,
      'heldCount': heldCount,
      'missingCount': missingCount,
      'heldMatchScore': heldMatchScore,
      'substituteMatchScore': substituteMatchScore,
      'missingMatchScore': missingMatchScore,
      'remainingPortfolioValue': remainingPortfolioValue,
      'investmentAmount': investmentAmount,
      'totalPortfolioValue': totalPortfolioValue,
      'minimumInvestmentAmount': minimumInvestmentAmount,
      'actualInvestmentCost': actualInvestmentCost,
      'budgetVariance': budgetVariance,
      'residualCash': residualCash,
      'budgetUtilization': budgetUtilization,
      'heldCoverageValue': heldCoverageValue,
      'excludedSymbols': excludedSymbols,
      'sectorialBasket': sectorialBasket,
      'dominantSector': dominantSector,
      'etfConstituentIsins': etfConstituentIsins,
      'appliedSubstituteCount': appliedSubstituteCount,
      'substituteWarnings': substituteWarnings,
      'composition': composition.map((e) => e.toJson()).toList(),
      'buyList': buyList.map((e) => e.toJson()).toList(),
    };
  }

  BasketOpportunity copyWith({
    String? etfIsin,
    String? etfName,
    double? matchScore,
    double? replicaScore,
    bool? readyToReplicate,
    int? totalItems,
    int? heldCount,
    int? missingCount,
    double? heldMatchScore,
    double? substituteMatchScore,
    double? missingMatchScore,
    double? remainingPortfolioValue,
    double? investmentAmount,
    double? totalPortfolioValue,
    double? minimumInvestmentAmount,
    double? actualInvestmentCost,
    double? budgetVariance,
    double? residualCash,
    double? budgetUtilization,
    double? heldCoverageValue,
    List<String>? excludedSymbols,
    bool? sectorialBasket,
    String? dominantSector,
    List<String>? etfConstituentIsins,
    int? appliedSubstituteCount,
    List<String>? substituteWarnings,
    List<BasketItem>? composition,
    List<BasketItem>? buyList,
  }) {
    return BasketOpportunity(
      etfIsin: etfIsin ?? this.etfIsin,
      etfName: etfName ?? this.etfName,
      matchScore: matchScore ?? this.matchScore,
      replicaScore: replicaScore ?? this.replicaScore,
      readyToReplicate: readyToReplicate ?? this.readyToReplicate,
      totalItems: totalItems ?? this.totalItems,
      heldCount: heldCount ?? this.heldCount,
      missingCount: missingCount ?? this.missingCount,
      heldMatchScore: heldMatchScore ?? this.heldMatchScore,
      substituteMatchScore: substituteMatchScore ?? this.substituteMatchScore,
      missingMatchScore: missingMatchScore ?? this.missingMatchScore,
      remainingPortfolioValue: remainingPortfolioValue ?? this.remainingPortfolioValue,
      investmentAmount: investmentAmount ?? this.investmentAmount,
      totalPortfolioValue: totalPortfolioValue ?? this.totalPortfolioValue,
      minimumInvestmentAmount: minimumInvestmentAmount ?? this.minimumInvestmentAmount,
      actualInvestmentCost: actualInvestmentCost ?? this.actualInvestmentCost,
      budgetVariance: budgetVariance ?? this.budgetVariance,
      residualCash: residualCash ?? this.residualCash,
      budgetUtilization: budgetUtilization ?? this.budgetUtilization,
      heldCoverageValue: heldCoverageValue ?? this.heldCoverageValue,
      excludedSymbols: excludedSymbols ?? this.excludedSymbols,
      sectorialBasket: sectorialBasket ?? this.sectorialBasket,
      dominantSector: dominantSector ?? this.dominantSector,
      etfConstituentIsins: etfConstituentIsins ?? this.etfConstituentIsins,
      appliedSubstituteCount: appliedSubstituteCount ?? this.appliedSubstituteCount,
      substituteWarnings: substituteWarnings ?? this.substituteWarnings,
      composition: composition ?? this.composition,
      buyList: buyList ?? this.buyList,
    );
  }
}

class BasketItem {
  final String stockSymbol;
  final String isin;
  final String sector;
  final ItemStatus status;
  final String? userHoldingSymbol;
  final String? userHoldingIsin;
  final String? reason;
  final double etfWeight;
  final double userWeight;
  final double replicaWeight;
  final double? rebalancedWeight;
  final double? buyQuantity;
  final double? lastPrice;
  final String? marketCapCategory;
  final double? marketCapValue;
  final double? targetQuantity;
  final bool targetQuantityLocked;
  final bool underfunded;
  final double? heldQuantity;
  final double? heldAveragePrice;
  final List<Alternative> alternatives;

  const BasketItem({
    required this.stockSymbol,
    required this.isin,
    required this.sector,
    required this.status,
    this.userHoldingSymbol,
    this.userHoldingIsin,
    this.reason,
    this.etfWeight = 0.0,
    this.userWeight = 0.0,
    this.replicaWeight = 0.0,
    this.rebalancedWeight,
    this.buyQuantity,
    this.lastPrice,
    this.marketCapCategory,
    this.marketCapValue,
    this.targetQuantity,
    this.targetQuantityLocked = false,
    this.underfunded = false,
    this.heldQuantity,
    this.heldAveragePrice,
    this.alternatives = const [],
  });

  factory BasketItem.fromJson(Map<String, dynamic> json) {
    return BasketItem(
      stockSymbol: json['stockSymbol'] as String? ?? 'Unknown',
      isin: json['isin'] as String? ?? '',
      sector: json['sector'] as String? ?? 'Unknown',
      status: ItemStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == (json['status'] as String?)?.toUpperCase(),
        orElse: () => ItemStatus.missing,
      ),
      userHoldingSymbol: json['userHoldingSymbol'] as String?,
      userHoldingIsin: json['userHoldingIsin'] as String?,
      reason: json['reason'] as String?,
      etfWeight: (json['etfWeight'] as num?)?.toDouble() ?? 0.0,
      userWeight: (json['userWeight'] as num?)?.toDouble() ?? 0.0,
      replicaWeight: (json['replicaWeight'] as num?)?.toDouble() ?? 0.0,
      rebalancedWeight: (json['rebalancedWeight'] as num?)?.toDouble(),
      buyQuantity: (json['buyQuantity'] as num?)?.toDouble(),
      lastPrice: (json['lastPrice'] as num?)?.toDouble(),
      marketCapCategory: json['marketCapCategory'] as String?,
      marketCapValue: (json['marketCapValue'] as num?)?.toDouble(),
      targetQuantity: (json['targetQuantity'] as num?)?.toDouble(),
      targetQuantityLocked: json['targetQuantityLocked'] as bool? ?? false,
      underfunded: json['underfunded'] as bool? ?? false,
      heldQuantity: (json['heldQuantity'] as num?)?.toDouble(),
      heldAveragePrice: (json['heldAveragePrice'] as num?)?.toDouble(),
      alternatives: (json['alternatives'] as List<dynamic>?)
              ?.map((e) => Alternative.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stockSymbol': stockSymbol,
      'isin': isin,
      'sector': sector,
      'status': status.name.toUpperCase(),
      'userHoldingSymbol': userHoldingSymbol,
      'userHoldingIsin': userHoldingIsin,
      'reason': reason,
      'etfWeight': etfWeight,
      'userWeight': userWeight,
      'replicaWeight': replicaWeight,
      'rebalancedWeight': rebalancedWeight,
      'buyQuantity': buyQuantity,
      'lastPrice': lastPrice,
      'marketCapCategory': marketCapCategory,
      'marketCapValue': marketCapValue,
      'targetQuantity': targetQuantity,
      'targetQuantityLocked': targetQuantityLocked,
      'underfunded': underfunded,
      'heldQuantity': heldQuantity,
      'heldAveragePrice': heldAveragePrice,
      'alternatives': alternatives.map((e) => e.toJson()).toList(),
    };
  }

  BasketItem copyWith({
    String? stockSymbol,
    String? isin,
    String? sector,
    String? marketCapCategory,
    ItemStatus? status,
    String? userHoldingSymbol,
    String? userHoldingIsin,
    String? reason,
    double? etfWeight,
    double? userWeight,
    double? replicaWeight,
    double? rebalancedWeight,
    double? buyQuantity,
    bool clearBuyQuantity = false,
    double? lastPrice,
    List<Alternative>? alternatives,
    double? targetQuantity,
    bool? targetQuantityLocked,
    bool? underfunded,
    double? heldQuantity,
    double? heldAveragePrice,
  }) {
    return BasketItem(
      stockSymbol: stockSymbol ?? this.stockSymbol,
      isin: isin ?? this.isin,
      sector: sector ?? this.sector,
      marketCapCategory: marketCapCategory ?? this.marketCapCategory,
      status: status ?? this.status,
      userHoldingSymbol: userHoldingSymbol ?? this.userHoldingSymbol,
      userHoldingIsin: userHoldingIsin ?? this.userHoldingIsin,
      reason: reason ?? this.reason,
      etfWeight: etfWeight ?? this.etfWeight,
      userWeight: userWeight ?? this.userWeight,
      replicaWeight: replicaWeight ?? this.replicaWeight,
      rebalancedWeight: rebalancedWeight ?? this.rebalancedWeight,
      buyQuantity: clearBuyQuantity ? null : (buyQuantity ?? this.buyQuantity),
      lastPrice: lastPrice ?? this.lastPrice,
      alternatives: alternatives ?? this.alternatives,
      targetQuantity: targetQuantity ?? this.targetQuantity,
      targetQuantityLocked: targetQuantityLocked ?? this.targetQuantityLocked,
      underfunded: underfunded ?? this.underfunded,
      heldQuantity: heldQuantity ?? this.heldQuantity,
      heldAveragePrice: heldAveragePrice ?? this.heldAveragePrice,
    );
  }
}

class Alternative {
  final String symbol;
  final String isin;
  final double userWeight;
  final double? quantity;
  final double? lastPrice;
  final String? sector;
  final bool isSameSector;
  final bool canFullyCover;
  final String? coverageLabel;

  const Alternative({
    required this.symbol,
    required this.isin,
    this.userWeight = 0.0,
    this.quantity,
    this.lastPrice,
    this.sector,
    this.isSameSector = false,
    this.canFullyCover = false,
    this.coverageLabel,
  });

  factory Alternative.fromJson(Map<String, dynamic> json) {
    return Alternative(
      symbol: json['symbol'] as String? ?? 'Unknown',
      isin: json['isin'] as String? ?? '',
      userWeight: (json['userWeight'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toDouble(),
      lastPrice: (json['lastPrice'] as num?)?.toDouble(),
      sector: json['sector'] as String?,
      isSameSector: json['isSameSector'] as bool? ?? false,
      canFullyCover: json['canFullyCover'] as bool? ?? false,
      coverageLabel: json['coverageLabel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'isin': isin,
      'userWeight': userWeight,
      'quantity': quantity,
      'lastPrice': lastPrice,
      'sector': sector,
      'isSameSector': isSameSector,
      'canFullyCover': canFullyCover,
      'coverageLabel': coverageLabel,
    };
  }

  Alternative copyWith({
    String? symbol,
    String? isin,
    double? userWeight,
    double? quantity,
    double? lastPrice,
    String? sector,
    bool? isSameSector,
    bool? canFullyCover,
    String? coverageLabel,
  }) {
    return Alternative(
      symbol: symbol ?? this.symbol,
      isin: isin ?? this.isin,
      userWeight: userWeight ?? this.userWeight,
      quantity: quantity ?? this.quantity,
      lastPrice: lastPrice ?? this.lastPrice,
      sector: sector ?? this.sector,
      isSameSector: isSameSector ?? this.isSameSector,
      canFullyCover: canFullyCover ?? this.canFullyCover,
      coverageLabel: coverageLabel ?? this.coverageLabel,
    );
  }
}

enum ItemStatus {
  held,
  missing,
  substitute,
  excluded,
}
