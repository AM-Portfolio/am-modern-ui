class StockSearchResult {
  final String symbol;
  final String name;
  final String? isin;
  final String? marketCapCategory;
  final double? marketCapValue;
  final String? sector;

  const StockSearchResult({
    required this.symbol,
    required this.name,
    this.isin,
    this.marketCapCategory,
    this.marketCapValue,
    this.sector,
  });

  factory StockSearchResult.fromJson(Map<String, dynamic> json) {
    return StockSearchResult(
      symbol: json['symbol'] ?? '',
      name: json['companyName'] ?? json['name'] ?? '', // Handle both companyName (from batch) and name (from search)
      isin: json['isin'],
      marketCapCategory: json['marketCapType'] ?? json['market_cap_category'], // Handle both keys
      marketCapValue: (json['marketCapValue'] as num?)?.toDouble(),
      sector: json['sector'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'isin': isin,
      'marketCapCategory': marketCapCategory,
      'marketCapValue': marketCapValue,
      'sector': sector,
    };
  }
}
