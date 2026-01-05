import 'package:am_design_system/am_design_system.dart';
import '../entities/portfolio_list.dart';
import '../repositories/portfolio_repository.dart';
import 'package:am_common/core/utils/logger.dart';

/// Use case for getting portfolios list
class GetPortfoliosList {
  const GetPortfoliosList(this._repository);
  final PortfolioRepository _repository;

  /// Execute the use case
  Future<PortfolioList> call(String userId) async {
    CommonLogger.methodEntry(
      'GetPortfoliosList.call',
      tag: 'GetPortfoliosList',
      metadata: {'userId': userId},
    );

    if (userId.isEmpty) {
      CommonLogger.error(
        'User ID validation failed - empty userId',
        tag: 'GetPortfoliosList',
      );
      throw ArgumentError('User ID cannot be empty');
    }

    try {
      CommonLogger.info(
        'Executing get portfolios list use case',
        tag: 'GetPortfoliosList',
      );

      final portfolioList = await _repository.getPortfoliosList(userId);

      CommonLogger.info(
        'Portfolio list retrieved successfully - ${portfolioList.count} portfolios found',
        tag: 'GetPortfoliosList',
      );

      CommonLogger.methodExit(
        'GetPortfoliosList.call',
        tag: 'GetPortfoliosList',
        metadata: {'status': 'success'},
      );

      return portfolioList;
    } catch (error) {
      CommonLogger.error(
        'Failed to execute GetPortfoliosList use case',
        tag: 'GetPortfoliosList',
        error: error,
        stackTrace: StackTrace.current,
      );

      CommonLogger.methodExit(
        'GetPortfoliosList.call',
        tag: 'GetPortfoliosList',
        metadata: {'status': 'error'},
      );

      rethrow;
    }
  }

  /// Get portfolios list with validation
  Future<PortfolioList> execute(String userId) async => call(userId);

  /// Check if user has any portfolios
  Future<bool> hasPortfolios(String userId) async {
    try {
      final portfolioList = await call(userId);
      return portfolioList.isNotEmpty;
    } catch (error) {
      CommonLogger.error(
        'Failed to check if user has portfolios',
        tag: 'GetPortfoliosList',
        error: error,
      );
      return false;
    }
  }

  /// Get portfolio count for user
  Future<int> getPortfolioCount(String userId) async {
    try {
      final portfolioList = await call(userId);
      return portfolioList.count;
    } catch (error) {
      CommonLogger.error(
        'Failed to get portfolio count',
        tag: 'GetPortfoliosList',
        error: error,
      );
      return 0;
    }
  }
}
