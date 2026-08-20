class BasketOpportunity {
  final String etfIsin;
  final String etfName;
  final double matchScore;
  final double replicaScore;
  final bool readyToReplicate;
  final int totalItems;
  final int heldCount;
  final int missingCount;
  final double? totalPortfolioValue;
  final double? minimumInvestmentAmount;
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
    this.totalPortfolioValue,
    this.minimumInvestmentAmount,
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
      totalPortfolioValue: (json['totalPortfolioValue'] as num?)?.toDouble(),
      minimumInvestmentAmount: (json['minimumInvestmentAmount'] as num?)?.toDouble(),
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
      'totalPortfolioValue': totalPortfolioValue,
      'minimumInvestmentAmount': minimumInvestmentAmount,
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
    double? totalPortfolioValue,
    double? minimumInvestmentAmount,
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
      totalPortfolioValue: totalPortfolioValue ?? this.totalPortfolioValue,
      minimumInvestmentAmount: minimumInvestmentAmount ?? this.minimumInvestmentAmount,
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
      'heldQuantity': heldQuantity,
      'heldAveragePrice': heldAveragePrice,
      'alternatives': alternatives.map((e) => e.toJson()).toList(),
    };
  }

  BasketItem copyWith({
    String? stockSymbol,
    String? isin,
    String? sector,
    ItemStatus? status,
    String? userHoldingSymbol,
    String? userHoldingIsin,
    String? reason,
    double? etfWeight,
    double? userWeight,
    double? replicaWeight,
    double? rebalancedWeight,
    double? buyQuantity,
    double? lastPrice,
    List<Alternative>? alternatives,
    double? heldQuantity,
    double? heldAveragePrice,
  }) {
    return BasketItem(
      stockSymbol: stockSymbol ?? this.stockSymbol,
      isin: isin ?? this.isin,
      sector: sector ?? this.sector,
      status: status ?? this.status,
      userHoldingSymbol: userHoldingSymbol ?? this.userHoldingSymbol,
      userHoldingIsin: userHoldingIsin ?? this.userHoldingIsin,
      reason: reason ?? this.reason,
      etfWeight: etfWeight ?? this.etfWeight,
      userWeight: userWeight ?? this.userWeight,
      replicaWeight: replicaWeight ?? this.replicaWeight,
      rebalancedWeight: rebalancedWeight ?? this.rebalancedWeight,
      buyQuantity: buyQuantity ?? this.buyQuantity,
      lastPrice: lastPrice ?? this.lastPrice,
      alternatives: alternatives ?? this.alternatives,
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
}
