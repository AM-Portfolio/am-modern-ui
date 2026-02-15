import 'package:flutter_bloc/flutter_bloc.dart';
import '../states/top_movers_state.dart';
import '../models/models.dart';
import 'allocation_cubit.dart'; // For AnalysisService interface

/// Cubit for managing top movers data state
class TopMoversCubit extends Cubit<TopMoversState> {
  final String portfolioId;
  final AnalysisService analysisService;
  
  TopMoversCubit({
    required this.portfolioId,
    required this.analysisService,
  }) : super(const TopMoversInitial());
  
  /// Load top movers data for a given timeFrame
  Future<void> loadTopMovers(TimeFrame timeFrame) async {
    emit(const TopMoversLoading());
    
    try {
      final movers = await analysisService.getTopMovers(
        portfolioId: portfolioId,
        timeFrame: timeFrame,
      );
      emit(TopMoversLoaded(movers, timeFrame));
    } catch (e, stackTrace) {
      emit(TopMoversError(e.toString(), stackTrace));
    }
  }
  
  /// Apply filter to current data
  void applyFilter(MoverFilter filter) {
    final currentState = state;
    if (currentState is TopMoversLoaded) {
      emit(TopMoversLoaded(
        currentState.movers,
        currentState.timeFrame,
        currentFilter: filter,
      ));
    }
  }
  
  /// Refresh current data
  Future<void> refresh() async {
    final currentState = state;
    if (currentState is TopMoversLoaded) {
      await loadTopMovers(currentState.timeFrame);
    }
  }
  
  /// Change time frame and reload data
  Future<void> changeTimeFrame(TimeFrame timeFrame) async {
    await loadTopMovers(timeFrame);
  }
}
