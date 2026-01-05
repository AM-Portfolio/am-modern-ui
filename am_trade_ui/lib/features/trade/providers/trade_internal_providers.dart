import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';

import 'package:am_common/core/network/api_client.dart';
import '../internal/data/datasources/trade_remote_data_source.dart';
import '../internal/data/repositories/trade_repository_impl.dart';
import '../internal/domain/entities/trade_calendar.dart';
import '../internal/domain/entities/trade_holding.dart';
import '../internal/domain/entities/trade_portfolio.dart';
import '../internal/domain/entities/trade_summary.dart';
import '../internal/domain/repositories/trade_repository.dart';
import '../internal/domain/usecases/get_trade_calendar.dart';
import '../internal/domain/usecases/get_trade_calendar_by_date_range.dart';
import '../internal/domain/usecases/get_trade_calendar_by_day.dart';
import '../internal/domain/usecases/get_trade_calendar_by_month.dart';
import '../internal/domain/usecases/get_trade_holdings.dart';
import '../internal/domain/usecases/get_trade_portfolios.dart';
import '../internal/domain/usecases/get_trade_summary.dart';
import '../presentation/models/trade_calendar_view_model.dart';
import '../presentation/models/trade_holding_view_model.dart';
import '../presentation/models/trade_portfolio_view_model.dart';
import 'package:am_common/core/di/network_providers.dart';

/// Provider for trade remote data source
final _tradeRemoteDataSourceProvider = FutureProvider<TradeRemoteDataSource>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final apiConfig = await ref.watch(appConfigProvider.future);

  return TradeRemoteDataSourceImpl(apiClient: apiClient, tradeConfig: apiConfig.api.trade);
});

/// Provider for trade repository
final _tradeRepositoryProvider = FutureProvider<TradeRepository>((ref) async {
  final remoteDataSource = await ref.watch(_tradeRemoteDataSourceProvider.future);

  return TradeRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Provider for GetTradePortfolios use case
final _getTradePortfoliosProvider = FutureProvider<GetTradePortfolios>((ref) async {
  final repository = await ref.watch(_tradeRepositoryProvider.future);
  return GetTradePortfolios(repository);
});

/// Provider for GetTradeHoldings use case
final _getTradeHoldingsProvider = FutureProvider<GetTradeHoldings>((ref) async {
  final repository = await ref.watch(_tradeRepositoryProvider.future);
  return GetTradeHoldings(repository);
});

/// Provider for GetTradeSummary use case
final _getTradeSummaryProvider = FutureProvider<GetTradeSummary>((ref) async {
  final repository = await ref.watch(_tradeRepositoryProvider.future);
  return GetTradeSummary(repository);
});

/// Provider for GetTradeCalendar use case (private)
final _getTradeCalendarProvider = FutureProvider<GetTradeCalendar>((ref) async {
  final repository = await ref.watch(_tradeRepositoryProvider.future);
  return GetTradeCalendar(repository);
});

/// Provider for GetTradeCalendar use case (public)
final getTradeCalendarProvider = FutureProvider<GetTradeCalendar>((ref) async {
  final repository = await ref.watch(_tradeRepositoryProvider.future);
  return GetTradeCalendar(repository);
});

/// Provider for GetTradeCalendarByMonth use case
final getTradeCalendarByMonthProvider = FutureProvider<GetTradeCalendarByMonth>((ref) async {
  final repository = await ref.watch(_tradeRepositoryProvider.future);
  return GetTradeCalendarByMonth(repository);
});

/// Provider for GetTradeCalendarByDay use case
final getTradeCalendarByDayProvider = FutureProvider<GetTradeCalendarByDay>((ref) async {
  final repository = await ref.watch(_tradeRepositoryProvider.future);
  return GetTradeCalendarByDay(repository);
});

/// Provider for GetTradeCalendarByDateRange use case
final getTradeCalendarByDateRangeProvider = FutureProvider<GetTradeCalendarByDateRange>((ref) async {
  final repository = await ref.watch(_tradeRepositoryProvider.future);
  return GetTradeCalendarByDateRange(repository);
});

/// Provider for trade portfolios list
final tradePortfoliosProvider = FutureProvider.family<TradePortfolioList, String>((ref, userId) async {
  final useCase = await ref.watch(_getTradePortfoliosProvider.future);
  return useCase(userId);
});

/// Provider for trade holdings
final tradeHoldingsProvider = FutureProvider.family<TradeHoldings, ({String userId, String portfolioId})>((
  ref,
  params,
) async {
  final useCase = await ref.watch(_getTradeHoldingsProvider.future);
  return useCase(params.userId, params.portfolioId);
});

/// Provider for trade summary
final tradeSummaryProvider = FutureProvider.family<TradeSummary, ({String userId, String portfolioId})>((
  ref,
  params,
) async {
  final useCase = await ref.watch(_getTradeSummaryProvider.future);
  return useCase(params.userId, params.portfolioId);
});

/// Provider for trade calendar
final tradeCalendarProvider = FutureProvider.family<TradeCalendar, ({String userId, String portfolioId})>((
  ref,
  params,
) async {
  final useCase = await ref.watch(_getTradeCalendarProvider.future);
  final result = await useCase(params.userId, params.portfolioId);
  return result;
});

/// Provider for watching trade holdings (stream) - returns view models
final tradeHoldingsStreamProvider =
    StreamProvider.family<TradeHoldingsViewModel, ({String userId, String portfolioId})>((ref, params) async* {
      final useCase = await ref.watch(_getTradeHoldingsProvider.future);
      yield* useCase.watch(params.userId, params.portfolioId).map(TradeHoldingsViewModel.fromEntity);
    });

/// Provider for watching trade summary (stream)
final tradeSummaryStreamProvider = StreamProvider.family<TradeSummary, ({String userId, String portfolioId})>((
  ref,
  params,
) async* {
  final useCase = await ref.watch(_getTradeSummaryProvider.future);
  yield* useCase.watch(params.userId, params.portfolioId);
});

/// Provider for watching trade portfolios (stream) - returns view models
final tradePortfoliosStreamProvider = StreamProvider.family<List<TradePortfolioViewModel>, String>((ref, userId) async* {
  final useCase = await ref.watch(_getTradePortfoliosProvider.future);
  yield* useCase.watch(userId).map((list) => TradePortfolioViewModel.fromEntityList(list.portfolios));
});

/// Provider for watching trade calendar (stream) - returns view models
final tradeCalendarStreamProvider =
    StreamProvider.family<TradeCalendarViewModel, ({String userId, String portfolioId})>((ref, params) async* {
      final useCase = await ref.watch(_getTradeCalendarProvider.future);
      yield* useCase.watch(params.userId, params.portfolioId).map(TradeCalendarViewModel.fromEntity);
    });

/// Provider for trade calendar by month - returns view model
final tradeCalendarByMonthProvider =
    FutureProvider.family<TradeCalendarViewModel, ({String userId, String portfolioId, int year, int month})>((
      ref,
      params,
    ) async {
      final useCase = await ref.watch(getTradeCalendarByMonthProvider.future);
      final result = await useCase(params.userId, params.portfolioId, year: params.year, month: params.month);
      return TradeCalendarViewModel.fromEntity(result);
    });
