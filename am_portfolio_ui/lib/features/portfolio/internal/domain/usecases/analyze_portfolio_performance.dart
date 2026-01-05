import '../entities/portfolio_summary.dart';
import '../repositories/portfolio_repository.dart';

/// Use case for analyzing portfolio performance
class AnalyzePortfolioPerformance {
  const AnalyzePortfolioPerformance(this._repository);
  final PortfolioRepository _repository;

  /// Get sector allocation analysis
  Future<List<SectorAllocation>> getSectorAllocation(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }

    return _repository.getSectorAllocation(userId);
  }

  /// Get top performing holdings
  Future<List<TopPerformer>> getTopPerformers(
    String userId, {
    int limit = 5,
  }) async {
    if (userId.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }

    if (limit <= 0) {
      throw ArgumentError('Limit must be greater than 0');
    }

    return _repository.getTopPerformers(userId, limit: limit);
  }

  /// Get worst performing holdings
  Future<List<TopPerformer>> getWorstPerformers(
    String userId, {
    int limit = 5,
  }) async {
    if (userId.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }

    if (limit <= 0) {
      throw ArgumentError('Limit must be greater than 0');
    }

    return _repository.getWorstPerformers(userId, limit: limit);
  }
}
