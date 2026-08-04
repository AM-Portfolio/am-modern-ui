import 'package:equatable/equatable.dart';

/// DTO for creating a new portfolio
class PortfolioCreateRequestDto extends Equatable {
  const PortfolioCreateRequestDto({
    required this.name,
    this.description,
    required this.currency,
    required this.initialCapital,
  });

  final String name;
  final String? description;
  final String currency;
  final double initialCapital;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        'currency': currency,
        'initialCapital': initialCapital,
      };

  @override
  List<Object?> get props => [name, description, currency, initialCapital];
}
