import 'package:am_design_system/am_design_system.dart';
import '../entities/portfolio_list.dart';
import '../repositories/portfolio_repository.dart';
import 'package:am_common/am_common.dart';

/// Use case for getting portfolios list
class GetPortfoliosList {
  const GetPortfoliosList(this._repository);
  final PortfolioRepository _repository;

  /// Execute the use case
  Future<PortfolioList> call() async {
    CommonLogger.methodEntry(
      'GetPortfoliosList.call',
      tag: 'GetPortfoliosList',
      metadata: {},
    );
    return _repository.getPortfoliosList();
  }

  /// Check if user has any portfolios
  Future<bool> hasPortfolios() async {
    try {
      final portfolioList = await call();
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
  Future<int> getPortfolioCount() async {
    try {
      final portfolioList = await call();
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
