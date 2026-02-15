import 'package:flutter_test/flutter_test.dart';
import 'package:am_analysis_core/am_analysis_core.dart';

void main() {
  group('AllocationCubit', () {
    test('initial state is AllocationInitial', () {
      final service = _MockAnalysisService();
      final cubit = AllocationCubit(
        portfolioId: 'test-id',
        analysisService: service,
      );
      
      expect(cubit.state, isA<AllocationInitial>());
    });
  });
}

// Simple mock service for testing
class _MockAnalysisService implements AnalysisService {
  @override
  Future<List<AllocationItem>> getAllocation({
    required String portfolioId,
    required GroupBy groupBy,
  }) async {
    return [];
  }

  @override
  Future<List<MoverItem>> getTopMovers({
    required String portfolioId,
    required TimeFrame timeFrame,
  }) async {
    return [];
  }

  @override
  Future<List<PerformanceDataPoint>> getPerformance({
    required String portfolioId,
    required TimeFrame timeFrame,
  }) async {
    return [];
  }
}
