import 'package:equatable/equatable.dart';

/// DTO for updating an existing portfolio
class PortfolioUpdateRequestDto extends Equatable {
  const PortfolioUpdateRequestDto({
    required this.name,
    this.description,
    required this.currency,
    this.initialCapital,
  });

  final String name;
  final String? description;
  final String currency;
  final double? initialCapital;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    if (description != null) 'description': description,
    'currency': currency,
    if (initialCapital != null) 'initialCapital': initialCapital,
  };

  @override
  List<Object?> get props => [name, description, currency, initialCapital];
}
