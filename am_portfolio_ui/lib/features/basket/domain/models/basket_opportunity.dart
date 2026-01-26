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
  final String? reason;
  final double etfWeight;
  final double userWeight;
  final double replicaWeight;
  final double buyQuantity;
  final double? lastPrice;
  final String? marketCapCategory;
  final double? marketCapValue;
  final List<Alternative> alternatives;

  const BasketItem({
    required this.stockSymbol,
    required this.isin,
    required this.sector,
    required this.status,
    this.userHoldingSymbol,
    this.reason,
    this.etfWeight = 0.0,
    this.userWeight = 0.0,
    this.replicaWeight = 0.0,
    this.buyQuantity = 0.0,
    this.lastPrice,
    this.marketCapCategory,
    this.marketCapValue,
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
      reason: json['reason'] as String?,
      etfWeight: (json['etfWeight'] as num?)?.toDouble() ?? 0.0,
      userWeight: (json['userWeight'] as num?)?.toDouble() ?? 0.0,
      replicaWeight: (json['replicaWeight'] as num?)?.toDouble() ?? 0.0,
      buyQuantity: (json['buyQuantity'] as num?)?.toDouble() ?? 0.0,
      lastPrice: (json['lastPrice'] as num?)?.toDouble(),
      marketCapCategory: json['marketCapCategory'] as String?,
      marketCapValue: (json['marketCapValue'] as num?)?.toDouble(),
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
      'reason': reason,
      'etfWeight': etfWeight,
      'userWeight': userWeight,
      'replicaWeight': replicaWeight,
      'buyQuantity': buyQuantity,
      'lastPrice': lastPrice,
      'marketCapCategory': marketCapCategory,
      'marketCapValue': marketCapValue,
      'alternatives': alternatives.map((e) => e.toJson()).toList(),
    };
  }

  BasketItem copyWith({
    String? stockSymbol,
    String? isin,
    String? sector,
    ItemStatus? status,
    String? userHoldingSymbol,
    String? reason,
    double? etfWeight,
    double? userWeight,
    double? replicaWeight,
    double? buyQuantity,
    double? lastPrice,
    List<Alternative>? alternatives,
  }) {
    return BasketItem(
      stockSymbol: stockSymbol ?? this.stockSymbol,
      isin: isin ?? this.isin,
      sector: sector ?? this.sector,
      status: status ?? this.status,
      userHoldingSymbol: userHoldingSymbol ?? this.userHoldingSymbol,
      reason: reason ?? this.reason,
      etfWeight: etfWeight ?? this.etfWeight,
      userWeight: userWeight ?? this.userWeight,
      replicaWeight: replicaWeight ?? this.replicaWeight,
      buyQuantity: buyQuantity ?? this.buyQuantity,
      lastPrice: lastPrice ?? this.lastPrice,
      alternatives: alternatives ?? this.alternatives,
    );
  }
}

class Alternative {
  final String symbol;
  final String isin;
  final double userWeight;

  const Alternative({
    required this.symbol,
    required this.isin,
    this.userWeight = 0.0,
  });

  factory Alternative.fromJson(Map<String, dynamic> json) {
    return Alternative(
      symbol: json['symbol'] as String? ?? 'Unknown',
      isin: json['isin'] as String? ?? '',
      userWeight: (json['userWeight'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'isin': isin,
      'userWeight': userWeight,
    };
  }

  Alternative copyWith({
    String? symbol,
    String? isin,
    double? userWeight,
  }) {
    return Alternative(
      symbol: symbol ?? this.symbol,
      isin: isin ?? this.isin,
      userWeight: userWeight ?? this.userWeight,
    );
  }
}

enum ItemStatus {
  held,
  missing,
  substitute,
}
