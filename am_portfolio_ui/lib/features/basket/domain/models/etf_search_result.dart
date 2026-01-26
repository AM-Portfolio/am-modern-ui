class EtfSearchResult {
  final String symbol;
  final String name;
  final String? isin;
  final String? assetClass;
  final String? marketCapCategory;

  const EtfSearchResult({
    required this.symbol,
    required this.name,
    this.isin,
    this.assetClass,
    this.marketCapCategory,
  });

  factory EtfSearchResult.fromJson(Map<String, dynamic> json) {
    return EtfSearchResult(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      isin: json['isin'],
      assetClass: json['asset_class'],
      marketCapCategory: json['market_cap_category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'isin': isin,
      'asset_class': assetClass,
      'market_cap_category': marketCapCategory,
    };
  }
}
