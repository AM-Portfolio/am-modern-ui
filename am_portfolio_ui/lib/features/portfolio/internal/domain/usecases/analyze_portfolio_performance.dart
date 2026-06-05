import '../entities/portfolio_summary.dart';
import '../repositories/portfolio_repository.dart';

/// Use case for analyzing portfolio performance
class AnalyzePortfolioPerformance {
  const AnalyzePortfolioPerformance(this._repository);
  final PortfolioRepository _repository;

  /// Get sector allocation analysis
  Future<List<SectorAllocation>> getSectorAllocation() async {
    

    return _repository.getSectorAllocation();
  }

  /// Get top performing holdings
  Future<List<TopPerformer>> getTopPerformers(
    {
    int limit = 5,
  }) async {
    

    if (limit <= 0) {
      throw ArgumentError('Limit must be greater than 0');
    }

    return _repository.getTopPerformers(limit: limit);
  }

  /// Get worst performing holdings
  Future<List<TopPerformer>> getWorstPerformers(
    {
    int limit = 5,
  }) async {
    

    if (limit <= 0) {
      throw ArgumentError('Limit must be greater than 0');
    }

    return _repository.getWorstPerformers(limit: limit);
  }
}
