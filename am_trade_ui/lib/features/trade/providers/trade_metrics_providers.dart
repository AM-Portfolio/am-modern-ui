import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';

import 'package:am_common/core/network/api_client.dart';
import '../internal/data/datasources/trade_metrics_remote_datasource.dart';
import '../internal/data/repositories/trade_metrics_repository_impl.dart';
import '../internal/domain/repositories/trade_metrics_repository.dart';
import '../internal/domain/usecases/get_trade_metrics.dart';
import '../internal/domain/usecases/get_metric_types.dart';
import '../presentation/metrics/cubit/trade_metrics_cubit.dart';
import 'package:am_common/core/di/network_providers.dart';

// Infrastructure

/// Provider for TradeMetricsRemoteDataSource
final _tradeMetricsRemoteDataSourceProvider = FutureProvider<TradeMetricsRemoteDataSource>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final apiConfig = await ref.watch(appConfigProvider.future);
  return TradeMetricsRemoteDataSourceImpl(apiClient: apiClient, tradeConfig: apiConfig.api.trade);
});

/// Provider for TradeMetricsRepository
final _tradeMetricsRepositoryProvider = FutureProvider<TradeMetricsRepository>((ref) async {
  final remoteDataSource = await ref.watch(_tradeMetricsRemoteDataSourceProvider.future);
  return TradeMetricsRepositoryImpl(remoteDataSource);
});

// Use Cases

/// Provider for GetTradeMetrics UseCase
final getTradeMetricsUseCaseProvider = FutureProvider<GetTradeMetrics>((ref) async {
  final repository = await ref.watch(_tradeMetricsRepositoryProvider.future);
  return GetTradeMetrics(repository);
});

// Presentation

/// Provider for GetMetricTypes UseCase
final getMetricTypesUseCaseProvider = FutureProvider<GetMetricTypes>((ref) async {
  final repository = await ref.watch(_tradeMetricsRepositoryProvider.future);
  return GetMetricTypes(repository);
});

/// Provider for TradeMetricsCubit
final tradeMetricsCubitProvider = FutureProvider<TradeMetricsCubit>((ref) async {
  final getTradeMetrics = await ref.watch(getTradeMetricsUseCaseProvider.future);
  final getMetricTypes = await ref.watch(getMetricTypesUseCaseProvider.future);
  return TradeMetricsCubit(getTradeMetrics: getTradeMetrics, getMetricTypes: getMetricTypes);
});
