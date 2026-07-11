import 'package:equatable/equatable.dart';
import '../../internal/data/dtos/portfolio_snapshot_dto.dart';

abstract class PortfolioHistoryState extends Equatable {
  const PortfolioHistoryState();
  @override
  List<Object?> get props => [];
}

class PortfolioHistoryInitial extends PortfolioHistoryState {}

class PortfolioHistoryLoading extends PortfolioHistoryState {}

class PortfolioHistoryLoaded extends PortfolioHistoryState {
  const PortfolioHistoryLoaded({
    required this.snapshots,
    required this.availableBrokers,
  });
  
  final List<PortfolioSnapshotDto> snapshots;
  final List<String> availableBrokers;

  @override
  List<Object?> get props => [snapshots, availableBrokers];
}

class PortfolioHistoryError extends PortfolioHistoryState {
  const PortfolioHistoryError(this.message);
  
  final String message;
  
  @override
  List<Object?> get props => [message];
}
