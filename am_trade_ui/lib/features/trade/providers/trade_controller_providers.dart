import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';

import 'package:am_common/core/network/api_client.dart';
import '../internal/data/datasources/trade_controller_remote_data_source.dart';
import '../internal/data/repositories/trade_controller_repository_impl.dart';
import '../internal/domain/repositories/trade_controller_repository.dart';
import '../internal/domain/usecases/add_trade.dart';
import '../internal/domain/usecases/delete_trade.dart';
import '../internal/domain/usecases/get_trades_by_portfolio.dart';
import '../internal/domain/usecases/update_trade.dart';
import '../presentation/cubit/trade_controller_cubit.dart';
import 'package:am_common/core/di/network_providers.dart';

/// Provider for trade controller remote data source
final _tradeControllerRemoteDataSourceProvider = FutureProvider<TradeControllerRemoteDataSource>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final apiConfig = await ref.watch(appConfigProvider.future);

  return TradeControllerRemoteDataSourceImpl(apiClient: apiClient, tradeConfig: apiConfig.api.trade);
});

/// Provider for trade controller repository
final _tradeControllerRepositoryProvider = FutureProvider<TradeControllerRepository>((ref) async {
  final remoteDataSource = await ref.watch(_tradeControllerRemoteDataSourceProvider.future);

  return TradeControllerRepositoryImpl(remoteDataSource: remoteDataSource);
});

/// Provider for AddTrade use case
final _addTradeProvider = FutureProvider<AddTrade>((ref) async {
  final repository = await ref.watch(_tradeControllerRepositoryProvider.future);
  return AddTrade(repository);
});

/// Provider for UpdateTrade use case
final _updateTradeProvider = FutureProvider<UpdateTrade>((ref) async {
  final repository = await ref.watch(_tradeControllerRepositoryProvider.future);
  return UpdateTrade(repository);
});

/// Provider for DeleteTrade use case
final _deleteTradeProvider = FutureProvider<DeleteTrade>((ref) async {
  final repository = await ref.watch(_tradeControllerRepositoryProvider.future);
  return DeleteTrade(repository);
});

/// Provider for GetTradesByPortfolio use case
final _getTradesByPortfolioProvider = FutureProvider<GetTradesByPortfolio>((ref) async {
  final repository = await ref.watch(_tradeControllerRepositoryProvider.future);
  return GetTradesByPortfolio(repository);
});

/// Provider for TradeControllerCubit
final tradeControllerCubitProvider = FutureProvider.autoDispose<TradeControllerCubit>((ref) async {
  final addTrade = await ref.watch(_addTradeProvider.future);
  final updateTrade = await ref.watch(_updateTradeProvider.future);
  final deleteTrade = await ref.watch(_deleteTradeProvider.future);
  final getTradesByPortfolio = await ref.watch(_getTradesByPortfolioProvider.future);

  return TradeControllerCubit(
    addTrade: addTrade,
    updateTrade: updateTrade,
    deleteTrade: deleteTrade,
    getTradesByPortfolio: getTradesByPortfolio,
  );
});

/// Provider for TradeControllerCubit with portfolio ID parameter
/// Use this when you need a cubit scoped to a specific portfolio
final tradeControllerCubitForPortfolioProvider = FutureProvider.family.autoDispose<TradeControllerCubit, String>((
  ref,
  portfolioId,
) async {
  final cubit = await ref.watch(tradeControllerCubitProvider.future);
  // Optionally load trades immediately for this portfolio
  cubit.loadTrades(portfolioId: portfolioId);
  return cubit;
});
