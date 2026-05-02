import 'package:am_design_system/am_design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:am_common/am_common.dart';
import '../../internal/domain/entities/portfolio_holding.dart';
import '../../internal/domain/entities/portfolio_summary.dart';
import '../../internal/services/portfolio_service.dart';
import 'portfolio_state.dart';
import '../../internal/data/dtos/portfolio_summary_dto.dart';
import '../../internal/data/dtos/portfolio_socket_update_dto.dart';
import 'package:get_it/get_it.dart';
import 'dart:convert';
import 'dart:async';
import 'package:am_common/am_common.dart';
import 'package:uuid/uuid.dart';


class PortfolioCubit extends Cubit<PortfolioState> {
  final String _debugId = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
  
  PortfolioCubit(this._portfolioService, {AmStompClient? stompClient}) 
      : _stompClient = stompClient ?? GetIt.instance<AmStompClient>(),
        super(PortfolioInitial());
        
  final PortfolioService _portfolioService;
  final AmStompClient _stompClient; // Use local instance
  
  // Subscription management
  bool _isSubscribed = false;
  StreamSubscription? _socketSubscription;
  String? _subUserId;
  String? _subPortfolioId;

  /// Subscribe to portfolio updates via WebSocket
  void subscribeToPortfolioUpdates(String userId, {String? portfolioId}) {
    _subUserId = userId;
    _subPortfolioId = portfolioId;
    if (_isSubscribed) {
      CommonLogger.debug('Already subscribed (flag is true)', tag: 'PortfolioCubit');
      return; 
    }

    CommonLogger.info('PortfolioCubit: Initiating subscription for user $userId', tag: 'PortfolioCubit');

    // Listen to connection status to subscribe when ready
    _stompClient.status.listen((status) {
      CommonLogger.info('[$_debugId] PortfolioCubit: Status changed to $status', tag: 'PortfolioCubit');
      if (status == StompStatus.connected && !_isSubscribed) {
         CommonLogger.info('[$_debugId] PortfolioCubit: Connected event received, calling _performSubscription', tag: 'PortfolioCubit');
         _performSubscription();
      }
    });
    
    // If already connected, subscribe immediately
    if (_stompClient.isConnected) {
      CommonLogger.info('PortfolioCubit: Already connected, subscribing immediately', tag: 'PortfolioCubit');
      _performSubscription();
    } else {
      CommonLogger.info('WebSocket not connected yet. Waiting for connection to subscribe...', tag: 'PortfolioCubit');
      
      // Add a delayed retry in case the status listener was registered after connection
      Future.delayed(const Duration(seconds: 2), () {
        if (!_isSubscribed && _stompClient.isConnected) {
          CommonLogger.info('PortfolioCubit: Delayed retry - connection detected, subscribing now', tag: 'PortfolioCubit');
          _performSubscription();
        }
      });
    }
  }

  void _performSubscription() {
     // AmStompClient handles idempotent subscriptions, but we can double check
     // effectively, we just want to ensure we call subscribe once valid.
     
     CommonLogger.info('[$_debugId] Hello', tag: 'PortfolioCubit');
     
     // Store the destination for unsubscription
     const destination = '/user/queue/portfolio';
     _stompClient.subscribe(destination);
     
     // Trigger the backend to start calculating using the /app/portfolio/subscribe endpoint
     if (_subUserId != null && _subPortfolioId != null) {
       final traceId = Uuid().v4();
       final body = '{"userId": "$_subUserId", "portfolioId": "$_subPortfolioId"}';
       
       CommonLogger.info('Triggering calculation for portfolio: $_subPortfolioId', tag: 'PortfolioCubit');
       
       _stompClient.send(
         destination: '/app/portfolio/subscribe',
         headers: {
           'X-Correlation-Id': traceId,
           'content-type': 'application/json',
         },
         body: body,
       );
     }
     
     if (!_isSubscribed) {
       CommonLogger.info('[$_debugId] 🎧 PortfolioCubit: Setting up message listener...', tag: 'PortfolioCubit');
       
       // Cancel any existing subscription before creating a new one
       _socketSubscription?.cancel();

       _socketSubscription = _stompClient.messages.listen((frame) {
         CommonLogger.info('[$_debugId] 📨 PortfolioCubit: Frame received from stream!', tag: 'PortfolioCubit');
         
         final destination = frame.headers['destination'];
         CommonLogger.info('[$_debugId] 📍 PortfolioCubit: Destination = $destination', tag: 'PortfolioCubit');
         
         if (destination != null && destination.contains('portfolio')) {
           CommonLogger.info('✅ PortfolioCubit: Destination matches "portfolio"', tag: 'PortfolioCubit');
           
           if (frame.body != null) {
             CommonLogger.info('📦 PortfolioCubit: Frame has body, length = ${frame.body!.length}', tag: 'PortfolioCubit');
             
             try {
                CommonLogger.info('⚙️ PortfolioCubit: Parsing JSON...', tag: 'PortfolioCubit');
                final json = jsonDecode(frame.body!);
                
                CommonLogger.info('💾 PortfolioCubit: Calling updateSummaryFromSocket with currentValue=${json['currentValue']}', tag: 'PortfolioCubit');
                updateSummaryFromSocket(json);
             } catch (e) {
               CommonLogger.error('❌ PortfolioCubit: Error parsing WebSocket message', error: e, tag: 'PortfolioCubit');
             }
           } else {
             CommonLogger.warning('⚠️ PortfolioCubit: Frame body is null', tag: 'PortfolioCubit');
           }
         } else {
           CommonLogger.debug('⏭️ PortfolioCubit: Skipping frame, destination does not contain "portfolio"', tag: 'PortfolioCubit');
         }
       });
       
       _isSubscribed = true;
       CommonLogger.info('✅ PortfolioCubit: Message listener setup complete', tag: 'PortfolioCubit');
     }
  }

  /// Unsubscribe from portfolio updates
  void unsubscribeFromPortfolioUpdates() {
    if (_isSubscribed) {
      CommonLogger.info('[$_debugId] PortfolioCubit: Unsubscribing from updates', tag: 'PortfolioCubit');
      _stompClient.unsubscribe('/user/queue/portfolio');
      
      // Cancel the stream subscription to stop listening to messages
      _socketSubscription?.cancel();
      _socketSubscription = null;
      
      _isSubscribed = false;
    }
  }

  @override
  Future<void> close() {
    unsubscribeFromPortfolioUpdates();
    return super.close();
  }

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

  /// Load only portfolio summary (without holdings) for overview page
  Future<void> loadPortfolioSummaryOnly(String userId, String portfolioId) async {
    CommonLogger.methodEntry(
      'loadPortfolioSummaryOnly',
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
          'Starting portfolio summary fetch (without holdings) by ID via service',
          tag: 'PortfolioCubit',
      );

      // Only fetch summary, not holdings
      final summary = await _portfolioService.getPortfolioSummaryById(userId, portfolioId);

      CommonLogger.stateChange(
        'PortfolioLoading',
        'PortfolioLoaded',
        tag: 'PortfolioCubit',
      );
      CommonLogger.info(
        'Portfolio summary loaded successfully by ID via service',
        tag: 'PortfolioCubit',
      );

      if (!isClosed) {
        // Emit with empty holdings list since we only need summary for overview
        emit(PortfolioLoaded(summary: summary, holdings: []));
      }

      CommonLogger.methodExit(
        'loadPortfolioSummaryOnly',
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
        'Failed to load portfolio summary by ID via service',
        tag: 'PortfolioCubit',
        error: error,
        stackTrace: StackTrace.current,
      );

      if (!isClosed) {
        emit(PortfolioError(error.toString()));
      }

      CommonLogger.methodExit(
        'loadPortfolioSummaryOnly',
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
        CommonLogger.debug('Processing WebSocket update in Cubit', tag: 'PortfolioCubit');
        // 1. Parse DTO using the specific Socket DTO
        final dto = PortfolioSocketUpdateDto.fromJson(json);
        
        // 2. Update Summary
        final updatedSummary = currentState.summary.copyWith(
          totalValue: dto.currentValue,
          investmentValue: dto.investmentValue,
          totalGainLoss: dto.totalGainLoss,
          totalGainLossPercentage: dto.totalGainLossPercentage,
          todayChange: dto.todayGainLoss,
          todayChangePercentage: dto.todayGainLossPercentage,
          lastUpdated: DateTime.now(),
        );

        // 3. Update Holdings if present in the update
        List<PortfolioHolding> updatedHoldings = currentState.holdings;
        
        if (dto.equities.isNotEmpty) {
           // Create a map of current holdings for easy lookup to preserve static fields (like name/sector if not in socket dto)
           // But actually, socket DTO has limited fields. We need to merge.
           // Ideally, we should fetch full data or have full data in socket. 
           // For now, we update strictly the pricing/value fields of matching holdings.
           
           updatedHoldings = currentState.holdings.map((existing) {
             final update = dto.equities.firstWhere(
               (e) => e.isin == existing.id || e.symbol == existing.symbol, 
               orElse: () => SocketEquityHoldingDto(
                 isin: '', symbol: '', quantity: 0, currentPrice: 0, currentValue: 0, 
                 investmentValue: 0, profitLoss: 0, profitLossPercentage: 0, 
                 todayProfitLoss: 0, todayProfitLossPercentage: 0
               ),
             );
             
             if (update.isin.isNotEmpty || update.symbol.isNotEmpty) {
               return existing.copyWith(
                 currentPrice: update.currentPrice,
                 currentValue: update.currentValue,
                 investedAmount: update.investmentValue,
                 totalGainLoss: update.profitLoss,
                 totalGainLossPercentage: update.profitLossPercentage,
                 todayChange: update.todayProfitLoss,
                 todayChangePercentage: update.todayProfitLossPercentage,
                 // potentially update quantity if changed
                 quantity: update.quantity > 0 ? update.quantity : existing.quantity, 
               );
             }
             return existing;
           }).toList();
        }

        emit(currentState.copyWith(summary: updatedSummary, holdings: updatedHoldings));
        CommonLogger.info('State updated from WebSocket: Val=${dto.currentValue}', tag: 'PortfolioCubit');
      } catch (e) {
        CommonLogger.error('Failed to update summary from socket', error: e, tag: 'PortfolioCubit');
      }
    }
  }
}

