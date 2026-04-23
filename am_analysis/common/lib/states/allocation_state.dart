import 'package:equatable/equatable.dart';
import '../models/models.dart';

/// Base class for all allocation states
abstract class AllocationState extends Equatable {
  const AllocationState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class AllocationInitial extends AllocationState {
  const AllocationInitial();
}

/// Loading state while fetching allocation data
class AllocationLoading extends AllocationState {
  const AllocationLoading();
}

/// Successfully loaded allocation data
class AllocationLoaded extends AllocationState {
  final List<AllocationItem> allocations;
  final GroupBy groupBy;
  
  const AllocationLoaded(this.allocations, this.groupBy);
  
  @override
  List<Object?> get props => [allocations, groupBy];
}

/// Error state with message
class AllocationError extends AllocationState {
  final String message;
  final StackTrace? stackTrace;
  
  const AllocationError(this.message, [this.stackTrace]);
  
  @override
  List<Object?> get props => [message, stackTrace];
}
