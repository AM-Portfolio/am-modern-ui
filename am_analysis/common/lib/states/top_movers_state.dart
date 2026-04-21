import 'package:equatable/equatable.dart';
import '../models/models.dart';

/// Base class for all top movers states
abstract class TopMoversState extends Equatable {
  const TopMoversState();
  
  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class TopMoversInitial extends TopMoversState {
  const TopMoversInitial();
}

/// Loading state while fetching top movers data
class TopMoversLoading extends TopMoversState {
  const TopMoversLoading();
}

/// Successfully loaded top movers data
class TopMoversLoaded extends TopMoversState {
  final List<MoverItem> movers;
  final TimeFrame timeFrame;
  final MoverFilter currentFilter;
  
  const TopMoversLoaded(
    this.movers,
    this.timeFrame, {
    this.currentFilter = MoverFilter.all,
  });
  
  /// Get filtered movers based on current filter
  List<MoverItem> get filteredMovers {
    switch (currentFilter) {
      case MoverFilter.gainers:
        return movers.where((m) => m.changePercentage > 0).toList();
      case MoverFilter.losers:
        return movers.where((m) => m.changePercentage < 0).toList();
      case MoverFilter.all:
        return movers;
    }
  }
  
  @override
  List<Object?> get props => [movers, timeFrame, currentFilter];
}

/// Error state with message
class TopMoversError extends TopMoversState {
  final String message;
  final StackTrace? stackTrace;
  
  const TopMoversError(this.message, [this.stackTrace]);
  
  @override
  List<Object?> get props => [message, stackTrace];
}

/// Enum for filtering movers
enum MoverFilter {
  all,
  gainers,
  losers,
}
