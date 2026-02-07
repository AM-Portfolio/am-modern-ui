import 'package:am_design_system/am_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_common/core/utils/logger.dart';
import '../../internal/domain/entities/portfolio_holding.dart';
import '../../internal/domain/entities/portfolio_summary.dart';
import '../../internal/services/portfolio_service.dart';
import 'portfolio_state.dart';
import '../../internal/data/dtos/portfolio_summary_dto.dart';

class PortfolioCubit extends Cubit<PortfolioState> {
  PortfolioCubit(this._portfolioService) : super(PortfolioInitial());
  final PortfolioService _portfolioService;

  Future<void> loadPortfolio(String userId) async {
    CommonLogger.methodEntry(
      'loadPortfolio',
      tag: 'PortfolioCubit',
      metadata: {'userId': userId},
    );
    CommonLogger.stateChange(
      '${state.runtimeType}',
      'PortfolioLoading',
      tag: 'PortfolioCubit',
    );

    emit(PortfolioLoading());

    try {
      CommonLogger.info(
        'Starting portfolio data fetch via service',
        tag: 'PortfolioCubit',
      );

      // Use portfolio service to fetch data concurrently
      final results = await Future.wait([
        _portfolioService.getPortfolioHoldings(userId),
        _portfolioService.getPortfolioSummary(userId),
      ]);

      final holdings = results[0] as PortfolioHoldings;
      final summary = results[1] as PortfolioSummary;

      CommonLogger.stateChange(
        'PortfolioLoading',
        'PortfolioLoaded',
        tag: 'PortfolioCubit',
      );
      CommonLogger.info(
        'Portfolio data loaded successfully via service (${holdings.holdings.length} holdings)',
        tag: 'PortfolioCubit',
      );

      if (!isClosed) {
        emit(PortfolioLoaded(summary: summary, holdings: holdings.holdings));
      }

      CommonLogger.methodExit(
        'loadPortfolio',
        tag: 'PortfolioCubit',
        metadata: {'status': 'success'},
      );
    } catch (error) {
      CommonLogger.stateChange(
        'PortfolioLoading',
        'PortfolioError',
        tag: 'PortfolioCubit',
        event: error.toString(),
      );
      CommonLogger.error(
        'Failed to load portfolio via service',
        tag: 'PortfolioCubit',
        error: error,
        stackTrace: StackTrace.current,
      );

      if (!isClosed) {
        emit(PortfolioError(error.toString()));
      }

      CommonLogger.methodExit(
        'loadPortfolio',
        tag: 'PortfolioCubit',
        metadata: {'status': 'error'},
      );
    }
  }

  /// Load portfolio data for a specific portfolio ID
  Future<void> loadPortfolioById(String userId, String portfolioId) async {
    CommonLogger.methodEntry(
      'loadPortfolioById',
      tag: 'PortfolioCubit',
      metadata: {'userId': userId, 'portfolioId': portfolioId},
    );
    CommonLogger.stateChange(
      '${state.runtimeType}',
      'PortfolioLoading',
      tag: 'PortfolioCubit',
    );

    emit(PortfolioLoading());

    try {
      CommonLogger.info(
        'Starting portfolio data fetch by ID via service',
        tag: 'PortfolioCubit',
      );

      // Use portfolio service to fetch data concurrently by portfolio ID
      final results = await Future.wait([
        _portfolioService.getPortfolioHoldingsById(userId, portfolioId),
        _portfolioService.getPortfolioSummaryById(userId, portfolioId),
      ]);

      final holdings = results[0] as PortfolioHoldings;
      final summary = results[1] as PortfolioSummary;

      CommonLogger.stateChange(
        'PortfolioLoading',
        'PortfolioLoaded',
        tag: 'PortfolioCubit',
      );
      CommonLogger.info(
        'Portfolio data loaded successfully by ID via service (${holdings.holdings.length} holdings)',
        tag: 'PortfolioCubit',
      );

      if (!isClosed) {
        emit(PortfolioLoaded(summary: summary, holdings: holdings.holdings));
      }

      CommonLogger.methodExit(
        'loadPortfolioById',
        tag: 'PortfolioCubit',
        metadata: {'status': 'success'},
      );
    } catch (error) {
      CommonLogger.stateChange(
        'PortfolioLoading',
        'PortfolioError',
        tag: 'PortfolioCubit',
        event: error.toString(),
      );
      CommonLogger.error(
        'Failed to load portfolio by ID via service',
        tag: 'PortfolioCubit',
        error: error,
        stackTrace: StackTrace.current,
      );

      if (!isClosed) {
        emit(PortfolioError(error.toString()));
      }

      CommonLogger.methodExit(
        'loadPortfolioById',
        tag: 'PortfolioCubit',
        metadata: {'status': 'error'},
      );
    }
  }

  void changeView(PortfolioViewType viewType) {
    final currentState = state;
    if (currentState is PortfolioLoaded) {
      emit(currentState.copyWith(currentView: viewType));
    }
  }

  Future<void> refreshPortfolio(String userId) async {
    final currentState = state;
    if (currentState is PortfolioLoaded) {
      try {
        CommonLogger.info(
          'Refreshing portfolio data via service',
          tag: 'PortfolioCubit',
        );

        // Keep current state while refreshing, set refreshing to true
        if (!isClosed) {
          emit(currentState.copyWith(isRefreshing: true));
        }

        // Use portfolio service to refresh data
        final results = await Future.wait([
          _portfolioService.getPortfolioHoldings(userId),
          _portfolioService.getPortfolioSummary(userId),
        ]);

        final holdings = results[0] as PortfolioHoldings;
        final summary = results[1] as PortfolioSummary;

        emit(
          currentState.copyWith(
            summary: summary,
            holdings: holdings.holdings,
            isRefreshing: false,
          ),
        );

        CommonLogger.info(
          'Portfolio data refreshed successfully via service',
          tag: 'PortfolioCubit',
        );
      } catch (error) {
        CommonLogger.error(
          'Failed to refresh portfolio via service',
          tag: 'PortfolioCubit',
          error: error,
        );
        if (!isClosed) {
          emit(PortfolioError(error.toString()));
        }
      }
    } else {
      loadPortfolio(userId);
    }
  }

  /// Refresh portfolio data for a specific portfolio ID
  Future<void> refreshPortfolioById(String userId, String portfolioId) async {
    final currentState = state;
    if (currentState is PortfolioLoaded) {
      try {
        CommonLogger.info(
          'Refreshing portfolio data by ID via service',
          tag: 'PortfolioCubit',
        );

        // Keep current state while refreshing, set refreshing to true
        if (!isClosed) {
          emit(currentState.copyWith(isRefreshing: true));
        }

        // Use portfolio service to refresh data by portfolio ID
        final results = await Future.wait([
          _portfolioService.getPortfolioHoldingsById(userId, portfolioId),
          _portfolioService.getPortfolioSummaryById(userId, portfolioId),
        ]);

        final holdings = results[0] as PortfolioHoldings;
        final summary = results[1] as PortfolioSummary;

        if (!isClosed) {
          emit(
            currentState.copyWith(
              summary: summary,
              holdings: holdings.holdings,
              isRefreshing: false,
            ),
          );
        }

        CommonLogger.info(
          'Portfolio data refreshed successfully by ID via service',
          tag: 'PortfolioCubit',
        );
      } catch (error) {
        CommonLogger.error(
          'Failed to refresh portfolio by ID via service',
          tag: 'PortfolioCubit',
          error: error,
        );
        if (!isClosed) {
          emit(PortfolioError(error.toString()));
        }
      }
    } else {
      loadPortfolioById(userId, portfolioId);
    }
  }

  /// Load portfolios list for the specified user
  Future<void> loadPortfoliosList(String userId) async {
    CommonLogger.methodEntry(
      'loadPortfoliosList',
      tag: 'PortfolioCubit',
      metadata: {'userId': userId},
    );
    CommonLogger.stateChange(
      '${state.runtimeType}',
      'PortfolioListLoading',
      tag: 'PortfolioCubit',
    );

    emit(PortfolioListLoading());

    try {
      CommonLogger.info(
        'Starting portfolio list fetch via service',
        tag: 'PortfolioCubit',
      );

      final portfolioList = await _portfolioService.getPortfoliosList(userId);

      CommonLogger.stateChange(
        'PortfolioListLoading',
        'PortfolioListLoaded',
        tag: 'PortfolioCubit',
      );
      CommonLogger.info(
        'Portfolio list loaded successfully via service (${portfolioList.count} portfolios)',
        tag: 'PortfolioCubit',
      );

      if (!isClosed) {
        emit(PortfolioListLoaded(portfolioList: portfolioList));
      }

      CommonLogger.methodExit(
        'loadPortfoliosList',
        tag: 'PortfolioCubit',
        metadata: {'status': 'success'},
      );
    } catch (error) {
      CommonLogger.stateChange(
        'PortfolioListLoading',
        'PortfolioListError',
        tag: 'PortfolioCubit',
        event: error.toString(),
      );
      CommonLogger.error(
        'Failed to load portfolio list via service',
        tag: 'PortfolioCubit',
        error: error,
        stackTrace: StackTrace.current,
      );

      if (!isClosed) {
        emit(PortfolioListError(error.toString()));
      }

      CommonLogger.methodExit(
        'loadPortfoliosList',
        tag: 'PortfolioCubit',
        metadata: {'status': 'error'},
      );
    }
  }

  /// Refresh portfolios list
  Future<void> refreshPortfoliosList(String userId) async {
    final currentState = state;
    if (currentState is PortfolioListLoaded) {
      try {
        CommonLogger.info(
          'Refreshing portfolio list via service',
          tag: 'PortfolioCubit',
        );

        // Keep current state while refreshing, set refreshing to true
        if (!isClosed) {
          emit(currentState.copyWith(isRefreshing: true));
        }

        final portfolioList = await _portfolioService.getPortfoliosList(userId);

        if (!isClosed) {
          emit(
            currentState.copyWith(
              portfolioList: portfolioList,
              isRefreshing: false,
            ),
          );
        }

        CommonLogger.info(
          'Portfolio list refreshed successfully via service',
          tag: 'PortfolioCubit',
        );
      } catch (error) {
        CommonLogger.error(
          'Failed to refresh portfolio list via service',
          tag: 'PortfolioCubit',
          error: error,
        );
        if (!isClosed) {
          emit(PortfolioListError(error.toString()));
        }
      }
    } else {
      loadPortfoliosList(userId);
    }
  }
  /// Update portfolio summary from WebSocket data
  void updateSummaryFromSocket(Map<String, dynamic> json) {
    if (isClosed) return;
    
    final currentState = state;
    if (currentState is PortfolioLoaded) {
      try {
        // 1. Parse DTO
        final dto = PortfolioSummaryDto.fromJson(json);
        
        // 2. Map to Domain Entity manually to avoid circular deps or complex mapper injection if not available
        // Or better, use the mapper if we can access it.
        // For now, let's map the essential fields to update the UI "live"
        // Note: The Domain Entity has different fields than DTO.
        // We really need the mapper.
        // Assuming we can't easily inject the mapper here without refactoring, 
        // let's do a best-effort mapping for key fields.
        
        final updatedSummary = currentState.summary.copyWith(
          totalValue: dto.totalValue,
          investmentValue: dto.investmentValue,
          totalGainLoss: dto.totalGain,
          totalGainLossPercentage: dto.totalGainPercentage,
          todayChange: dto.todaysGain,
          todayChangePercentage: dto.todaysGainPercentage,
          lastUpdated: DateTime.now(),
        );

        emit(currentState.copyWith(summary: updatedSummary));
      } catch (e) {
        CommonLogger.error('Failed to update summary from socket', error: e, tag: 'PortfolioCubit');
      }
    }
  }
}
