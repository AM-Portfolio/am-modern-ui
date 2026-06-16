import 'package:am_design_system/am_design_system.dart';
import '../domain/entities/portfolio_holding.dart';
import '../domain/entities/portfolio_summary.dart';
import '../domain/entities/portfolio_list.dart';
import '../domain/usecases/get_portfolio_holdings.dart';
import '../domain/usecases/get_portfolio_summary.dart';
import '../domain/usecases/get_portfolios_list.dart';
import 'package:am_common/am_common.dart';

/// Portfolio orchestration service for core workflows.
///
/// Combines core use cases and coordinates essential operations like:
/// - Portfolio data retrieval
/// - Summary information access
/// - Holdings management
///
/// This service acts as a facade that combines core use cases
/// to perform essential portfolio operations.
class PortfolioService {
  const PortfolioService(
    this._getPortfolioHoldings,
    this._getPortfolioSummary,
    this._getPortfoliosList,
  );
  final GetPortfolioHoldings _getPortfolioHoldings;
  final GetPortfolioSummary _getPortfolioSummary;
  final GetPortfoliosList _getPortfoliosList;

  /// Retrieves portfolio holdings for the specified user
  /// Returns holdings data or throws an exception if retrieval fails
  Future<PortfolioHoldings> getPortfolioHoldings() async {
    CommonLogger.methodEntry(
      'getPortfolioHoldings',
      tag: 'PortfolioService',
      metadata: {},
    );

    try {
      CommonLogger.info('Getting portfolio holdings', tag: 'PortfolioService');
      final holdings = await _getPortfolioHoldings.call('');

      CommonLogger.info(
        'Portfolio holdings retrieved successfully',
        tag: 'PortfolioService',
      );
      CommonLogger.methodExit(
        'getPortfolioHoldings',
        tag: 'PortfolioService',
        metadata: {'status': 'success'},
      );

      return holdings;
    } catch (error) {
      CommonLogger.error(
        'Failed to get portfolio holdings',
        tag: 'PortfolioService',
        error: error,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfolioHoldings',
        tag: 'PortfolioService',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  /// Retrieves portfolio holdings for the specified user and portfolio
  /// Returns holdings data or throws an exception if retrieval fails
  Future<PortfolioHoldings> getPortfolioHoldingsById(
    String portfolioId,
  ) async {
    CommonLogger.methodEntry(
      'getPortfolioHoldingsById',
      tag: 'PortfolioService',
      metadata: {'portfolioId': portfolioId},
    );

    try {
      CommonLogger.info(
        'Getting portfolio holdings by ID',
        tag: 'PortfolioService',
      );
      final holdings = await _getPortfolioHoldings.call(portfolioId);

      CommonLogger.info(
        'Portfolio holdings retrieved successfully by ID',
        tag: 'PortfolioService',
      );
      CommonLogger.methodExit(
        'getPortfolioHoldingsById',
        tag: 'PortfolioService',
        metadata: {'status': 'success'},
      );

      return holdings;
    } catch (error) {
      CommonLogger.error(
        'Failed to get portfolio holdings by ID',
        tag: 'PortfolioService',
        error: error,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfolioHoldingsById',
        tag: 'PortfolioService',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  /// Gets cached portfolio holdings for the specified user and portfolio
  Future<PortfolioHoldings?> getCachedPortfolioHoldingsById(String portfolioId) async {
    return _getPortfolioHoldings.getCached(portfolioId);
  }

  /// Retrieves portfolio summary for the specified user
  /// Returns summary data or throws an exception if retrieval fails
  Future<PortfolioSummary> getPortfolioSummary() async {
    CommonLogger.methodEntry(
      'getPortfolioSummary',
      tag: 'PortfolioService',
      metadata: {},
    );

    try {
      CommonLogger.info('Getting portfolio summary', tag: 'PortfolioService');
      final summary = await _getPortfolioSummary.call('');

      CommonLogger.info(
        'Portfolio summary retrieved successfully',
        tag: 'PortfolioService',
      );
      CommonLogger.methodExit(
        'getPortfolioSummary',
        tag: 'PortfolioService',
        metadata: {'status': 'success'},
      );

      return summary;
    } catch (error) {
      CommonLogger.error(
        'Failed to get portfolio summary',
        tag: 'PortfolioService',
        error: error,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfolioSummary',
        tag: 'PortfolioService',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  /// Retrieves portfolio summary for the specified user and portfolio
  /// Returns summary data or throws an exception if retrieval fails
  Future<PortfolioSummary> getPortfolioSummaryById(
    String portfolioId,
  ) async {
    CommonLogger.methodEntry(
      'getPortfolioSummaryById',
      tag: 'PortfolioService',
      metadata: {'portfolioId': portfolioId},
    );

    try {
      CommonLogger.info(
        'Getting portfolio summary by ID',
        tag: 'PortfolioService',
      );
      final summary = await _getPortfolioSummary.call(portfolioId);

      CommonLogger.info(
        'Portfolio summary retrieved successfully by ID',
        tag: 'PortfolioService',
      );
      CommonLogger.methodExit(
        'getPortfolioSummaryById',
        tag: 'PortfolioService',
        metadata: {'status': 'success'},
      );

      return summary;
    } catch (error) {
      CommonLogger.error(
        'Failed to get portfolio summary by ID',
        tag: 'PortfolioService',
        error: error,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfolioSummaryById',
        tag: 'PortfolioService',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  /// Gets cached portfolio summary for the specified user and portfolio
  Future<PortfolioSummary?> getCachedPortfolioSummaryById(String portfolioId) async {
    return _getPortfolioSummary.getCached(portfolioId);
  }

  /// Retrieves portfolios list for the specified user
  /// Returns portfolio list data or throws an exception if retrieval fails
  Future<PortfolioList> getPortfoliosList() async {
    CommonLogger.methodEntry(
      'getPortfoliosList',
      tag: 'PortfolioService',
      metadata: {},
    );

    try {
      CommonLogger.info('Getting portfolios list', tag: 'PortfolioService');
      final portfolioList = await _getPortfoliosList.call();

      CommonLogger.info(
        'Portfolios list retrieved successfully',
        tag: 'PortfolioService',
      );
      CommonLogger.methodExit(
        'getPortfoliosList',
        tag: 'PortfolioService',
        metadata: {'status': 'success'},
      );

      return portfolioList;
    } catch (error) {
      CommonLogger.error(
        'Failed to get portfolios list',
        tag: 'PortfolioService',
        error: error,
        stackTrace: StackTrace.current,
      );
      CommonLogger.methodExit(
        'getPortfoliosList',
        tag: 'PortfolioService',
        metadata: {'status': 'error'},
      );
      rethrow;
    }
  }

  /// Validates basic portfolio data consistency
  /// Returns true if portfolio data appears consistent
  Future<bool> validatePortfolioConsistency() async {
    try {
      final results = await Future.wait([
        _getPortfolioHoldings.call(''),
        _getPortfolioSummary.call(''),
      ]);

      // Basic validation - can be expanded when freezed code is generated
      // For now, just ensure we can retrieve both holdings and summary
      return results.isNotEmpty;
    } catch (error) {
      return false;
    }
  }
}
