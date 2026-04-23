import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_common/core/config/config_service.dart';
import 'package:am_common/core/config/app_config.dart';
import '../internal/data/datasources/trade_report_remote_datasource.dart';
import '../internal/data/repositories/trade_report_repository_impl.dart';
import '../internal/domain/repositories/trade_report_repository.dart';
import '../internal/domain/usecases/get_trade_performance_summary_usecase.dart';
import '../internal/domain/usecases/get_daily_performance_usecase.dart';
import '../internal/domain/usecases/get_timing_analysis_usecase.dart';
import '../presentation/report/cubit/trade_report_cubit.dart';
import 'package:am_library/am_library.dart';

import 'package:am_common/core/di/network_providers.dart';

final tradeReportRemoteDataSourceProvider = FutureProvider<TradeReportRemoteDataSource>((ref) async {
  final apiClient = await ref.watch(apiClientProvider.future);
  final apiConfig = await ref.watch(appConfigProvider.future);
  return TradeReportRemoteDataSource(apiClient, apiConfig.api.trade); 
});

final tradeReportRepositoryProvider = FutureProvider<TradeReportRepository>((ref) async {
  final remoteDataSource = await ref.watch(tradeReportRemoteDataSourceProvider.future);
  return TradeReportRepositoryImpl(remoteDataSource);
});

final getTradePerformanceSummaryUseCaseProvider = FutureProvider<GetTradePerformanceSummaryUseCase>((ref) async {
  final repository = await ref.watch(tradeReportRepositoryProvider.future);
  return GetTradePerformanceSummaryUseCase(repository);
});

final getDailyPerformanceUseCaseProvider = FutureProvider<GetDailyPerformanceUseCase>((ref) async {
  final repository = await ref.watch(tradeReportRepositoryProvider.future);
  return GetDailyPerformanceUseCase(repository);
});

final getTimingAnalysisUseCaseProvider = FutureProvider<GetTimingAnalysisUseCase>((ref) async {
  final repository = await ref.watch(tradeReportRepositoryProvider.future);
  return GetTimingAnalysisUseCase(repository);
});

final tradeReportCubitProvider = FutureProvider<TradeReportCubit>((ref) async {
  return TradeReportCubit(
    await ref.watch(getTradePerformanceSummaryUseCaseProvider.future),
    await ref.watch(getDailyPerformanceUseCaseProvider.future),
    await ref.watch(getTimingAnalysisUseCaseProvider.future),
  );
});
