import '../models/analysis_models.dart';
import '../models/analysis_enums.dart';

abstract class AnalysisService {
  Future<List<AllocationItem>> getAllocation(
    String? id,
    AnalysisEntityType type, {
    GroupBy? groupBy,
  });

  Future<List<PerformanceDataPoint>> getPerformance(
    String? id,
    AnalysisEntityType type,
    String timeFrame,
  );

  Future<List<MoverItem>> getTopMovers({
    String? id,
    AnalysisEntityType? type,
    String? timeFrame,
    GroupBy? groupBy,
  });
}

class MockAnalysisService implements AnalysisService {
  @override
  Future<List<AllocationItem>> getAllocation(
    String? id,
    AnalysisEntityType type, {
    GroupBy? groupBy,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      AllocationItem(name: 'Technology', percentage: 45.0, value: 45000),
      AllocationItem(name: 'Finance', percentage: 25.0, value: 25000),
      AllocationItem(name: 'Healthcare', percentage: 15.0, value: 15000),
      AllocationItem(name: 'Consumer', percentage: 10.0, value: 10000),
      AllocationItem(name: 'Energy', percentage: 5.0, value: 5000),
    ];
  }

  @override
  Future<List<PerformanceDataPoint>> getPerformance(
    String? id,
    AnalysisEntityType type,
    String timeFrame,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now();
    return List.generate(30, (index) {
      return PerformanceDataPoint(
        date: now.subtract(Duration(days: 30 - index)),
        value: 10000 + (index * 100) + (index % 2 == 0 ? 50 : -50),
      );
    });
  }

  @override
  Future<List<MoverItem>> getTopMovers({
    String? id,
    AnalysisEntityType? type,
    String? timeFrame,
    GroupBy? groupBy,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return [
      MoverItem(symbol: 'AAPL', name: 'Apple Inc.', price: 175.50, changePercentage: 2.5, changeAmount: 4.30),
      MoverItem(symbol: 'GOOGL', name: 'Alphabet Inc.', price: 135.20, changePercentage: 1.8, changeAmount: 2.40),
      MoverItem(symbol: 'AMZN', name: 'Amazon.com', price: 145.00, changePercentage: -0.5, changeAmount: -0.75),
      MoverItem(symbol: 'MSFT', name: 'Microsoft', price: 330.00, changePercentage: -1.2, changeAmount: -4.00),
    ];
  }
}
