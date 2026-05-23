import 'dart:async';

import 'package:am_common/am_common.dart';
import '../../domain/entities/favorite_filter.dart';
import '../../domain/entities/trade_calendar.dart';
import '../../domain/entities/trade_holding.dart';
import '../../domain/entities/trade_portfolio.dart';
import '../../domain/entities/trade_summary.dart';
import '../../domain/repositories/trade_repository.dart';
import '../datasources/trade_remote_data_source.dart';
import '../mappers/trade_calendar_mapper.dart';
import '../mappers/trade_holding_mapper.dart';
import '../mappers/trade_portfolio_mapper.dart';
import '../mappers/trade_summary_mapper.dart';
import '../dtos/trade_portfolio_dto.dart';
import 'package:am_library/am_library.dart';
import 'dart:convert';

/// Repository implementation for trade data operations
class TradeRepositoryImpl implements TradeRepository {
  TradeRepositoryImpl({
    required TradeRemoteDataSource remoteDataSource,
    AmStompClient? stompClient,
  }) : _remoteDataSource = remoteDataSource,
       _stompClient = stompClient;

  final TradeRemoteDataSource _remoteDataSource;
  final AmStompClient? _stompClient;
  StreamSubscription? _stompSubscription;

  // Stream controllers for real-time updates
  final StreamController<TradePortfolioList> _portfoliosController = StreamController<TradePortfolioList>.broadcast();
  final StreamController<TradeHoldings> _holdingsController = StreamController<TradeHoldings>.broadcast();
  final StreamController<TradeSummary> _summaryController = StreamController<TradeSummary>.broadcast();
  final StreamController<TradeCalendar> _calendarController = StreamController<TradeCalendar>.broadcast();
  final StreamController<FavoriteFilterList> _filtersController = StreamController<FavoriteFilterList>.broadcast();

  // Cache for the latest data
  TradePortfolioList? _cachedPortfolioList;
  TradeHoldings? _cachedHoldings;
  TradeSummary? _cachedSummary;
  TradeCalendar? _cachedCalendar;
  FavoriteFilterList? _cachedFilterList;

  @override
  Future<TradePortfolioList> getTradePortfolios() async {
    AppLogger.methodEntry('getTradePortfolios', tag: 'TradeRepository', params: {});

    try {
      final dto = await _remoteDataSource.getTradePortfolios();
      final portfolioList = TradePortfolioMapper.fromListDto(dto);

      _cachedPortfolioList = portfolioList;
      _portfoliosController.add(portfolioList);

      AppLogger.info('Trade portfolios fetched successfully', tag: 'TradeRepository');
      AppLogger.methodExit('getTradePortfolios', tag: 'TradeRepository', result: 'success');

      return portfolioList;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade portfolios',
        tag: 'TradeRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('getTradePortfolios', tag: 'TradeRepository', result: 'error');

      if (_cachedPortfolioList != null) {
        AppLogger.info('Returning cached trade portfolios', tag: 'TradeRepository');
        return _cachedPortfolioList!;
      }

      rethrow;
    }
  }

  @override
  Future<TradeHoldings> getTradeHoldings(String portfolioId) async {
    AppLogger.methodEntry(
      'getTradeHoldings',
      tag: 'TradeRepository',
      params: {},
    );

    try {
      final dto = await _remoteDataSource.getTradeHoldings(portfolioId);
      final holdings = TradeHoldingMapper.fromListDto(dto, portfolioId);

      _cachedHoldings = holdings;
      _holdingsController.add(holdings);

      AppLogger.info('Trade holdings fetched successfully', tag: 'TradeRepository');
      AppLogger.methodExit('getTradeHoldings', tag: 'TradeRepository', result: 'success');

      return holdings;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade holdings',
        tag: 'TradeRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('getTradeHoldings', tag: 'TradeRepository', result: 'error');

      if (_cachedHoldings != null) {
        AppLogger.info('Returning cached trade holdings', tag: 'TradeRepository');
        return _cachedHoldings!;
      }

      rethrow;
    }
  }

  @override
  Future<TradeSummary> getTradeSummary(String portfolioId) async {
    AppLogger.methodEntry(
      'getTradeSummary',
      tag: 'TradeRepository',
      params: {},
    );

    try {
      final dto = await _remoteDataSource.getTradeSummary(portfolioId);
      final summary = TradeSummaryMapper.fromPortfolioSummaryDto(dto);

      _cachedSummary = summary;
      _summaryController.add(summary);

      AppLogger.info('Trade summary fetched successfully', tag: 'TradeRepository');
      AppLogger.methodExit('getTradeSummary', tag: 'TradeRepository', result: 'success');

      return summary;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade summary',
        tag: 'TradeRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('getTradeSummary', tag: 'TradeRepository', result: 'error');

      if (_cachedSummary != null) {
        AppLogger.info('Returning cached trade summary', tag: 'TradeRepository');
        return _cachedSummary!;
      }

      rethrow;
    }
  }

  @override
  Future<TradeCalendar> getTradeCalendarByMonth(String portfolioId, {
    required int year,
    required int month,
  }) async {
    AppLogger.methodEntry(
      'getTradeCalendarByMonth',
      tag: 'TradeRepository',
      params: {},
    );

    try {
      final dto = await _remoteDataSource.getTradeCalendarByMonth(portfolioId, year: year, month: month);
      final calendar = TradeCalendarMapper.fromDto(dto);

      _cachedCalendar = calendar;
      _calendarController.add(calendar);

      AppLogger.info('Trade calendar by month fetched successfully', tag: 'TradeRepository');
      AppLogger.methodExit('getTradeCalendarByMonth', tag: 'TradeRepository', result: 'success');

      return calendar;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade calendar by month',
        tag: 'TradeRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('getTradeCalendarByMonth', tag: 'TradeRepository', result: 'error');

      if (_cachedCalendar != null) {
        AppLogger.info('Returning cached trade calendar', tag: 'TradeRepository');
        return _cachedCalendar!;
      }

      rethrow;
    }
  }

  @override
  Future<TradeCalendar> getTradeCalendarByDay(String portfolioId, {required DateTime date}) async {
    AppLogger.methodEntry(
      'getTradeCalendarByDay',
      tag: 'TradeRepository',
      params: {},
    );

    try {
      final dto = await _remoteDataSource.getTradeCalendarByDay(portfolioId, date: date);
      final calendar = TradeCalendarMapper.fromDto(dto);

      AppLogger.info('Trade calendar by day fetched successfully', tag: 'TradeRepository');
      AppLogger.methodExit('getTradeCalendarByDay', tag: 'TradeRepository', result: 'success');

      return calendar;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade calendar by day',
        tag: 'TradeRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('getTradeCalendarByDay', tag: 'TradeRepository', result: 'error');

      rethrow;
    }
  }

  @override
  Future<TradeCalendar> getTradeCalendarByDateRange(String portfolioId, {
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    AppLogger.methodEntry(
      'getTradeCalendarByDateRange',
      tag: 'TradeRepository',
      params: {},
    );

    try {
      final dto = await _remoteDataSource.getTradeCalendarByDateRange(portfolioId,
        startDate: startDate,
        endDate: endDate,
      );
      final calendar = TradeCalendarMapper.fromDto(dto);

      AppLogger.info('Trade calendar by date range fetched successfully', tag: 'TradeRepository');
      AppLogger.methodExit('getTradeCalendarByDateRange', tag: 'TradeRepository', result: 'success');

      return calendar;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade calendar by date range',
        tag: 'TradeRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('getTradeCalendarByDateRange', tag: 'TradeRepository', result: 'error');

      rethrow;
    }
  }

  @override
  Future<TradeCalendar> getTradeCalendarByQuarter(String portfolioId, {
    required int year,
    required int quarter,
  }) async {
    AppLogger.methodEntry(
      'getTradeCalendarByQuarter',
      tag: 'TradeRepository',
      params: {},
    );

    try {
      final dto = await _remoteDataSource.getTradeCalendarByQuarter(portfolioId, year: year, quarter: quarter);
      final calendar = TradeCalendarMapper.fromDto(dto);

      _cachedCalendar = calendar;
      _calendarController.add(calendar);

      AppLogger.info('Trade calendar by quarter fetched successfully', tag: 'TradeRepository');
      AppLogger.methodExit('getTradeCalendarByQuarter', tag: 'TradeRepository', result: 'success');

      return calendar;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade calendar by quarter',
        tag: 'TradeRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('getTradeCalendarByQuarter', tag: 'TradeRepository', result: 'error');

      if (_cachedCalendar != null) {
        AppLogger.info('Returning cached trade calendar', tag: 'TradeRepository');
        return _cachedCalendar!;
      }

      rethrow;
    }
  }

  @override
  Future<TradeCalendar> getTradeCalendarByFinancialYear(String portfolioId, {
    required int financialYear,
  }) async {
    AppLogger.methodEntry(
      'getTradeCalendarByFinancialYear',
      tag: 'TradeRepository',
      params: {},
    );

    try {
      final dto = await _remoteDataSource.getTradeCalendarByFinancialYear(portfolioId,
        financialYear: financialYear,
      );
      final calendar = TradeCalendarMapper.fromDto(dto);

      _cachedCalendar = calendar;
      _calendarController.add(calendar);

      AppLogger.info('Trade calendar by financial year fetched successfully', tag: 'TradeRepository');
      AppLogger.methodExit('getTradeCalendarByFinancialYear', tag: 'TradeRepository', result: 'success');

      return calendar;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch trade calendar by financial year',
        tag: 'TradeRepository',
        error: e,
        stackTrace: StackTrace.current,
      );
      AppLogger.methodExit('getTradeCalendarByFinancialYear', tag: 'TradeRepository', result: 'error');

      if (_cachedCalendar != null) {
        AppLogger.info('Returning cached trade calendar', tag: 'TradeRepository');
        return _cachedCalendar!;
      }

      rethrow;
    }
  }

  @override
  Future<TradeCalendar> getTradeCalendar(String portfolioId, {int? year, int? month}) async {
    // Legacy method - delegates to getTradeCalendarByMonth
    final now = DateTime.now();
    final targetYear = year ?? now.year;
    final targetMonth = month ?? now.month;

    return getTradeCalendarByMonth(portfolioId, year: targetYear, month: targetMonth);
  }

  @override
  Stream<TradeHoldings> watchTradeHoldings(String portfolioId) {
    AppLogger.methodEntry(
      'watchTradeHoldings',
      tag: 'TradeRepository',
      params: {},
    );

    // Check if cache exists AND matches the requested portfolio
    if (_cachedHoldings != null && _cachedHoldings!.portfolioId == portfolioId) {
      Future.microtask(() => _holdingsController.add(_cachedHoldings!));
    } else {
      getTradeHoldings(portfolioId).catchError((error) {
        AppLogger.error('Failed to fetch initial holdings for stream', tag: 'TradeRepository', error: error);
        _holdingsController.addError(error);
        return TradeHoldings.empty('', portfolioId);
      });
    }

    return _holdingsController.stream;
  }

  @override
  Stream<TradePortfolioList> watchTradePortfolios() {
    AppLogger.methodEntry('watchTradePortfolios', tag: 'TradeRepository', params: {});

    _ensureWebSocketSubscribed('');

    if (_cachedPortfolioList != null) {
      Future.microtask(() => _portfoliosController.add(_cachedPortfolioList!));
    } else {
      getTradePortfolios().catchError((error) {
        AppLogger.error('Failed to fetch initial portfolios for stream', tag: 'TradeRepository', error: error);
        _portfoliosController.addError(error);
        return TradePortfolioList.empty('');
      });
    }

    return _portfoliosController.stream;
  }

  @override
  Stream<TradeSummary> watchTradeSummary(String portfolioId) {
    AppLogger.methodEntry(
      'watchTradeSummary',
      tag: 'TradeRepository',
      params: {},
    );

    // Check if cache exists AND matches the requested portfolio
    if (_cachedSummary != null && _cachedSummary!.portfolioId == portfolioId) {
      Future.microtask(() => _summaryController.add(_cachedSummary!));
    } else {
      getTradeSummary(portfolioId).catchError((error) {
        AppLogger.error('Failed to fetch initial summary for stream', tag: 'TradeRepository', error: error);
        _summaryController.addError(error);
        return TradeSummary.empty(portfolioId, '');
      });
    }

    return _summaryController.stream;
  }

  @override
  Stream<TradeCalendar> watchTradeCalendar(String portfolioId) {
    AppLogger.methodEntry(
      'watchTradeCalendar',
      tag: 'TradeRepository',
      params: {},
    );

    _ensureWebSocketSubscribed('');

    // Check if cache exists AND contains data for the requested portfolio
    if (_cachedCalendar != null && _cachedCalendar!.portfolioTrades.containsKey(portfolioId)) {
      Future.microtask(() => _calendarController.add(_cachedCalendar!));
    } else {
      getTradeCalendar(portfolioId).catchError((error) {
        AppLogger.error('Failed to fetch initial calendar for stream', tag: 'TradeRepository', error: error);
        _calendarController.addError(error);
        return TradeCalendar.empty('', portfolioId);
      });
    }

    return _calendarController.stream;
  }

  void _ensureWebSocketSubscribed(String defaultUserId) {
    if (_stompClient == null) {
      AppLogger.warning('AmStompClient is null. WebSocket features disabled.', tag: 'TradeRepository');
      return;
    }

    final destination = '/user/queue/portfolio';

    if (_stompSubscription == null) {
      AppLogger.info('📡 Subscribing to: $destination', tag: 'TradeRepository');
      _stompClient!.subscribe(destination);

      _stompSubscription = _stompClient!.messages
          .where((frame) => frame.headers['destination'] == destination)
          .listen(
        (frame) {
          if (frame.body == null) return;
          try {
            final json = jsonDecode(frame.body!);
            AppLogger.info('Received real-time portfolio update via WebSocket', tag: 'TradeRepository');

            // Map the update to our entity
            final dto = TradePortfolioDto.fromJson(json);
            final updatedPortfolio = TradePortfolioMapper.fromDto(dto);
            
            // Merge with existing cache
            if (_cachedPortfolioList != null) {
              final existingPortfolios = List<TradePortfolio>.from(_cachedPortfolioList!.portfolios);
              final index = existingPortfolios.indexWhere((p) => p.id == updatedPortfolio.id);
              
              if (index != -1) {
                existingPortfolios[index] = updatedPortfolio;
              } else {
                existingPortfolios.add(updatedPortfolio);
              }
              
              _cachedPortfolioList = _cachedPortfolioList!.copyWith(portfolios: existingPortfolios);
            } else {
              _cachedPortfolioList = TradePortfolioList(userId: defaultUserId, portfolios: [updatedPortfolio]);
            }
            
            _portfoliosController.add(_cachedPortfolioList!);
          } catch (e) {
            AppLogger.error('Failed to parse portfolio STOMP message', error: e, tag: 'TradeRepository');
          }
        },
        onError: (err) => AppLogger.error('STOMP Subscription error', error: err, tag: 'TradeRepository'),
      );
    }
  }

  /// Dispose method to clean up resources
  void dispose() {
    AppLogger.methodEntry('dispose', tag: 'TradeRepository');

    _stompSubscription?.cancel();
    _stompClient?.unsubscribe('/user/queue/portfolio');

    _portfoliosController.close();
    _holdingsController.close();
    _summaryController.close();
    _calendarController.close();
    _cachedPortfolioList = null;
    _cachedHoldings = null;
    _cachedSummary = null;
    _cachedCalendar = null;
    _cachedFilterList = null;

    _filtersController.close();

    AppLogger.info('TradeRepository disposed', tag: 'TradeRepository');
  }
}

