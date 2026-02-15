import 'package:equatable/equatable.dart';
import '../models/models.dart';

/// Base class for all performance states
abstract class PerformanceState extends Equatable {
  const PerformanceState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class PerformanceInitial extends PerformanceState {
  const PerformanceInitial();
}

/// Loading state while fetching performance data
class PerformanceLoading extends PerformanceState {
  const PerformanceLoading();
}

/// Successfully loaded performance data
class PerformanceLoaded extends PerformanceState {
  final List<PerformanceDataPoint> dataPoints;
  final TimeFrame timeFrame;
  
  const PerformanceLoaded(this.dataPoints, this.timeFrame);
  
  @override
  List<Object?> get props => [dataPoints, timeFrame];
}

/// Error state with message
class PerformanceError extends PerformanceState {
  final String message;
  final StackTrace? stackTrace;
  
  const PerformanceError(this.message, [this.stackTrace]);
  
  @override
  List<Object?> get props => [message, stackTrace];
}
