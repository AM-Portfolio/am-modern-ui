import 'package:am_design_system/am_design_system.dart';
import '../entities/portfolio_summary.dart';
import '../repositories/portfolio_repository.dart';
import 'package:am_common/am_common.dart';

/// Use case for getting portfolio summary
class GetPortfolioSummary {
  const GetPortfolioSummary(this._repository);
  final PortfolioRepository _repository;

  /// Execute the use case
  Future<PortfolioSummary> call(String userId, [String? portfolioId]) async {
    CommonLogger.methodEntry(
      'GetPortfolioSummary.call',
      tag: 'GetPortfolioSummary',
      metadata: {'userId': userId, 'portfolioId': portfolioId},
    );

    if (userId.isEmpty) {
      CommonLogger.error(
        'User ID validation failed - empty userId',
        tag: 'GetPortfolioSummary',
      );
      throw ArgumentError('User ID cannot be empty');
    }

    try {
      CommonLogger.info(
        'Executing get portfolio summary use case',
        tag: 'GetPortfolioSummary',
      );

      // Call the appropriate repository method based on whether portfolioId is provided
      final result = portfolioId != null && portfolioId.isNotEmpty
          ? await _repository.getPortfolioSummaryById(userId, portfolioId)
          : await _repository.getPortfolioSummary(userId);

      CommonLogger.info(
        'Portfolio summary use case completed successfully',
        tag: 'GetPortfolioSummary',
      );
      CommonLogger.methodExit(
        'GetPortfolioSummary.call',
        tag: 'GetPortfolioSummary',
        metadata: {'status': 'success'},
      );

      return result;
    } catch (e) {
      CommonLogger.error(
        'Portfolio summary use case failed',
        tag: 'GetPortfolioSummary',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'GetPortfolioSummary.call',
        tag: 'GetPortfolioSummary',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  /// Get portfolio summary for user only (legacy method)
  Future<PortfolioSummary> callForUser(String userId) async => call(userId);

  /// Get portfolio summary for specific portfolio
  Future<PortfolioSummary> callForPortfolio(
    String userId,
    String portfolioId,
  ) async => call(userId, portfolioId);

  /// Execute with stream for real-time updates
  Stream<PortfolioSummary> watchSummary(String userId) {
    if (userId.isEmpty) {
      throw ArgumentError('User ID cannot be empty');
    }

    return _repository.watchPortfolioSummary(userId);
  }
}
