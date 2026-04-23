import 'package:flutter_bloc/flutter_bloc.dart';
import '../states/allocation_state.dart';
import '../models/models.dart';

/// Service interface that Cubits depend on for data
abstract class AnalysisService {
  Future<List<AllocationItem>> getAllocation({
    required String portfolioId,
    required GroupBy groupBy,
  });
  
  Future<List<MoverItem>> getTopMovers({
    required String portfolioId,
    required TimeFrame timeFrame,
  });
  
  Future<List<PerformanceDataPoint>> getPerformance({
    required String portfolioId,
    required TimeFrame timeFrame,
  });
}

/// Cubit for managing allocation data state
class AllocationCubit extends Cubit<AllocationState> {
  final String portfolioId;
  final AnalysisService analysisService;
  
  AllocationCubit({
    required this.portfolioId,
    required this.analysisService,
  }) : super(const AllocationInitial());
  
  /// Load allocation data for a given groupBy
  Future<void> loadAllocation(GroupBy groupBy) async {
    emit(const AllocationLoading());
    
    try {
      final allocations = await analysisService.getAllocation(
        portfolioId: portfolioId,
        groupBy: groupBy,
      );
      emit(AllocationLoaded(allocations, groupBy));
    } catch (e, stackTrace) {
      emit(AllocationError(e.toString(), stackTrace));
    }
  }
  
  /// Refresh current allocation data
  Future<void> refresh() async {
    final currentState = state;
    if (currentState is AllocationLoaded) {
      await loadAllocation(currentState.groupBy);
    }
  }
  
  /// Change groupBy and reload data
  Future<void> changeGroupBy(GroupBy groupBy) async {
    await loadAllocation(groupBy);
  }
}
