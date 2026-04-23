import 'package:flutter_bloc/flutter_bloc.dart';
import '../states/performance_state.dart';
import '../models/models.dart';
import 'allocation_cubit.dart'; // For AnalysisService interface

/// Cubit for managing performance data state
class PerformanceCubit extends Cubit<PerformanceState> {
  final String portfolioId;
  final AnalysisService analysisService;
  
  PerformanceCubit({
    required this.portfolioId,
    required this.analysisService,
  }) : super(const PerformanceInitial());
  
  /// Load performance data for a given timeFrame
  Future<void> loadPerformance(TimeFrame timeFrame) async {
    emit(const PerformanceLoading());
    
    try {
      final dataPoints = await analysisService.getPerformance(
        portfolioId: portfolioId,
        timeFrame: timeFrame,
      );
      emit(PerformanceLoaded(dataPoints, timeFrame));
    } catch (e, stackTrace) {
      emit(PerformanceError(e.toString(), stackTrace));
    }
  }
  
  /// Refresh current data
  Future<void> refresh() async {
    final currentState = state;
    if (currentState is PerformanceLoaded) {
      await loadPerformance(currentState.timeFrame);
    }
  }
  
  /// Change time frame and reload data
  Future<void> changeTimeFrame(TimeFrame timeFrame) async {
    await loadPerformance(timeFrame);
  }
}
