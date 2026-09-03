import '../models/basket_opportunity.dart';

class BasketDraftSummary {
  final String id;
  final String sourcePortfolioId;
  final String etfIsin;
  final String? etfName;
  final String? basketName;
  final double? investmentAmount;
  final double? replicaScore;
  final bool hasCalculated;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  const BasketDraftSummary({
    required this.id,
    required this.sourcePortfolioId,
    required this.etfIsin,
    this.etfName,
    this.basketName,
    this.investmentAmount,
    this.replicaScore,
    this.hasCalculated = false,
    this.updatedAt,
    this.createdAt,
  });

  factory BasketDraftSummary.fromJson(Map<String, dynamic> json) {
    return BasketDraftSummary(
      id: json['id'] as String,
      sourcePortfolioId: json['sourcePortfolioId'] as String? ?? '',
      etfIsin: json['etfIsin'] as String? ?? '',
      etfName: json['etfName'] as String?,
      basketName: json['basketName'] as String?,
      investmentAmount: (json['investmentAmount'] as num?)?.toDouble(),
      replicaScore: (json['replicaScore'] as num?)?.toDouble(),
      hasCalculated: json['hasCalculated'] as bool? ?? false,
      updatedAt: _parseDate(json['updatedAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

class BasketDraftDetail {
  final String id;
  final String userId;
  final String sourcePortfolioId;
  final String etfIsin;
  final String? etfName;
  final String? basketName;
  final double? investmentAmount;
  final double? replicaScore;
  final bool hasCalculated;
  final List<String> excludedSymbols;
  final Map<String, int> manualQtyOverrides;
  final BasketOpportunity? opportunity;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  const BasketDraftDetail({
    required this.id,
    required this.userId,
    required this.sourcePortfolioId,
    required this.etfIsin,
    this.etfName,
    this.basketName,
    this.investmentAmount,
    this.replicaScore,
    this.hasCalculated = false,
    this.excludedSymbols = const [],
    this.manualQtyOverrides = const {},
    this.opportunity,
    this.updatedAt,
    this.createdAt,
  });

  factory BasketDraftDetail.fromJson(Map<String, dynamic> json) {
    final overridesRaw = json['manualQtyOverrides'];
    final overrides = <String, int>{};
    if (overridesRaw is Map) {
      overridesRaw.forEach((key, value) {
        if (value is num) overrides[key.toString()] = value.toInt();
      });
    }
    final oppRaw = json['opportunity'];
    return BasketDraftDetail(
      id: json['id'] as String,
      userId: json['userId'] as String? ?? '',
      sourcePortfolioId: json['sourcePortfolioId'] as String? ?? '',
      etfIsin: json['etfIsin'] as String? ?? '',
      etfName: json['etfName'] as String?,
      basketName: json['basketName'] as String?,
      investmentAmount: (json['investmentAmount'] as num?)?.toDouble(),
      replicaScore: (json['replicaScore'] as num?)?.toDouble(),
      hasCalculated: json['hasCalculated'] as bool? ?? false,
      excludedSymbols: (json['excludedSymbols'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      manualQtyOverrides: overrides,
      opportunity: oppRaw is Map<String, dynamic>
          ? BasketOpportunity.fromJson(oppRaw)
          : (oppRaw is Map
              ? BasketOpportunity.fromJson(Map<String, dynamic>.from(oppRaw))
              : null),
      updatedAt: _parseDate(json['updatedAt']),
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

class BasketDraftListResult {
  final List<BasketDraftSummary> drafts;
  final int draftCount;
  final int draftLimit;

  const BasketDraftListResult({
    required this.drafts,
    required this.draftCount,
    this.draftLimit = 5,
  });

  factory BasketDraftListResult.fromJson(Map<String, dynamic> json) {
    final list = (json['drafts'] as List?) ?? const [];
    return BasketDraftListResult(
      drafts: list
          .map((e) => BasketDraftSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      draftCount: (json['draftCount'] as num?)?.toInt() ?? list.length,
      draftLimit: (json['draftLimit'] as num?)?.toInt() ?? 5,
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
