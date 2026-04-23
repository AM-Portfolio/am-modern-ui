import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_common/am_common.dart';
import '../../../internal/domain/entities/metrics/metrics_filter_request.dart';
import '../../../internal/domain/usecases/get_trade_performance_summary_usecase.dart';
import '../../../internal/domain/usecases/get_daily_performance_usecase.dart';
import '../../../internal/domain/usecases/get_timing_analysis_usecase.dart';
import 'trade_report_state.dart';

class TradeReportCubit extends Cubit<TradeReportState> {
  final GetTradePerformanceSummaryUseCase _getSummaryUseCase;
  final GetDailyPerformanceUseCase _getDailyUseCase;
  final GetTimingAnalysisUseCase _getTimingUseCase;

  TradeReportCubit(
    this._getSummaryUseCase,
    this._getDailyUseCase,
    this._getTimingUseCase,
  ) : super(TradeReportInitial());

  Future<void> loadReport(MetricsFilterRequest filter) async {
    try {
      emit(TradeReportLoading());
      
      // Fetch all data in parallel
      AppLogger.debug('Cubit: Starting parallel fetch', tag: 'TradeReportCubit');
      final results = await Future.wait([
        _getSummaryUseCase(filter),
        _getDailyUseCase(filter),
        _getTimingUseCase(filter),
      ]);
      AppLogger.debug('Cubit: Parallel fetch complete', tag: 'TradeReportCubit');

      emit(TradeReportLoaded(
        summary: results[0] as dynamic,
        dailyPerformance: results[1] as dynamic,
        timingAnalysis: results[2] as dynamic,
      ));
    } catch (e) {
      emit(TradeReportError(e.toString()));
    }
  }
}

