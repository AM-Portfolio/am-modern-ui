import 'package:am_design_system/am_design_system.dart';
import '../entities/portfolio_holding.dart';
import '../repositories/portfolio_repository.dart';
import 'package:am_common/am_common.dart';

/// Use case for getting portfolio holdings
class GetPortfolioHoldings {
  const GetPortfolioHoldings(this._repository);
  final PortfolioRepository _repository;

  /// Execute the use case
  Future<PortfolioHoldings> call(String userId, [String? portfolioId]) async {
    CommonLogger.methodEntry(
      'GetPortfolioHoldings.call',
      tag: 'GetPortfolioHoldings',
      metadata: {'userId': userId, 'portfolioId': portfolioId},
    );

    if (userId.isEmpty) {
      CommonLogger.error(
        'User ID validation failed - empty userId',
        tag: 'GetPortfolioHoldings',
      );
      throw ArgumentError('User ID cannot be empty');
    }

    try {
      CommonLogger.info(
        'Executing get portfolio holdings use case',
        tag: 'GetPortfolioHoldings',
      );

      // Call the appropriate repository method based on whether portfolioId is provided
      final result = portfolioId != null && portfolioId.isNotEmpty
          ? await _repository.getPortfolioHoldingsById(userId, portfolioId)
          : await _repository.getPortfolioHoldings(userId);

      CommonLogger.info(
        'Portfolio holdings use case completed successfully',
        tag: 'GetPortfolioHoldings',
      );
      CommonLogger.methodExit(
        'GetPortfolioHoldings.call',
        tag: 'GetPortfolioHoldings',
        metadata: {'status': 'success'},
      );

      return result;
    } catch (e) {
      CommonLogger.error(
        'Portfolio holdings use case failed',
        tag: 'GetPortfolioHoldings',
        error: e,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'GetPortfolioHoldings.call',
        tag: 'GetPortfolioHoldings',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  /// Get portfolio holdings for user only (legacy method)
  Future<PortfolioHoldings> callForUser(String userId) async => call(userId);

  /// Get portfolio holdings for specific portfolio
  Future<PortfolioHoldings> callForPortfolio(
    String userId,
    String portfolioId,
  ) async => call(userId, portfolioId);

  /// Execute with stream for real-time updates
  Stream<PortfolioHoldings> watchHoldings(String userId) {
    CommonLogger.methodEntry(
      'GetPortfolioHoldings.watchHoldings',
      tag: 'GetPortfolioHoldings',
      metadata: {'userId': userId},
    );

    if (userId.isEmpty) {
      CommonLogger.error(
        'User ID validation failed - empty userId for stream',
        tag: 'GetPortfolioHoldings',
      );
      throw ArgumentError('User ID cannot be empty');
    }

    CommonLogger.info(
      'Starting portfolio holdings stream',
      tag: 'GetPortfolioHoldings',
    );
    return _repository.watchPortfolioHoldings(userId);
  }
}

