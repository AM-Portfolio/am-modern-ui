import 'package:collection/collection.dart';

/// API response model for individual portfolio item in the list
/// This model directly maps to the API response structure
class PortfolioItemDto {
  const PortfolioItemDto({
    required this.portfolioId,
    required this.portfolioName,
  });

  /// Create from JSON
  factory PortfolioItemDto.fromJson(Map<String, dynamic> json) =>
      PortfolioItemDto(
        portfolioId: json['portfolioId'] as String,
        portfolioName: json['portfolioName'] as String,
      );
  final String portfolioId;
  final String portfolioName;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'portfolioId': portfolioId,
    'portfolioName': portfolioName,
  };

  @override
  String toString() =>
      'PortfolioItemDto(portfolioId: $portfolioId, portfolioName: $portfolioName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PortfolioItemDto &&
        other.portfolioId == portfolioId &&
        other.portfolioName == portfolioName;
  }

  @override
  int get hashCode => portfolioId.hashCode ^ portfolioName.hashCode;
}

/// API response model for portfolio list
/// This model directly maps to the API response structure for the list endpoint
class PortfolioListDto {
  const PortfolioListDto({required this.portfolios});

  /// Create from JSON array response
  factory PortfolioListDto.fromJson(List<dynamic> json) => PortfolioListDto(
    portfolios: json
        .map((item) => PortfolioItemDto.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
  final List<PortfolioItemDto> portfolios;

  /// Convert to JSON array
  List<Map<String, dynamic>> toJson() =>
      portfolios.map((portfolio) => portfolio.toJson()).toList();

  /// Check if the list is empty
  bool get isEmpty => portfolios.isEmpty;

  /// Check if the list is not empty
  bool get isNotEmpty => portfolios.isNotEmpty;

  /// Get the count of portfolios
  int get count => portfolios.length;

  @override
  String toString() =>
      'PortfolioListDto(portfolios: ${portfolios.length} items)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PortfolioListDto &&
        const ListEquality().equals(other.portfolios, portfolios);
  }

  @override
  int get hashCode => const ListEquality().hash(portfolios);
}
