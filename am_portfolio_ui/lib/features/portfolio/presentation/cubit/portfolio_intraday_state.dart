import 'package:equatable/equatable.dart';
import '../../internal/data/dtos/portfolio_intraday_dto.dart';

sealed class PortfolioIntradayState extends Equatable {
  const PortfolioIntradayState();

  @override
  List<Object?> get props => [];
}

class PortfolioIntradayInitial extends PortfolioIntradayState {}

class PortfolioIntradayLoading extends PortfolioIntradayState {}

class PortfolioIntradayLoaded extends PortfolioIntradayState {
  final List<PortfolioIntradayDto> data;

  const PortfolioIntradayLoaded(this.data);

  @override
  List<Object?> get props => [data];
}

class PortfolioIntradayEmpty extends PortfolioIntradayState {}

class PortfolioIntradayError extends PortfolioIntradayState {
  final String message;

  const PortfolioIntradayError(this.message);

  @override
  List<Object?> get props => [message];
}
