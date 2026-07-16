import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:am_design_system/am_design_system.dart' show CommonLogger;
import 'package:am_library/am_library.dart';
import '../../internal/data/datasources/portfolio_remote_data_source.dart';
import 'portfolio_intraday_state.dart';

class PortfolioIntradayCubit extends Cubit<PortfolioIntradayState> {
  PortfolioIntradayCubit(this._dataSource) : super(PortfolioIntradayInitial());

  final PortfolioRemoteDataSource _dataSource;
  Timer? _timer;
  String? _lastPortfolioId;

  void startLiveUpdates(String? portfolioId) {
    _lastPortfolioId = portfolioId;
    _load();
    // Refresh every 60 seconds during market hours
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _load());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _load() async {
    if (state is PortfolioIntradayInitial) {
      emit(PortfolioIntradayLoading());
    }

    final sw = Stopwatch()..start();
    try {
      final data = await _dataSource.getPortfolioIntraday(_lastPortfolioId);
      sw.stop();
      ProductTelemetry.instance.widgetTiming(
        widget: 'portfolio_intraday',
        durationMs: sw.elapsedMilliseconds,
        operation: 'fetch',
        technicalArea: 'portfolio',
      );
      if (data.isEmpty) {
        ProductTelemetry.instance.emptyState('intraday_empty');
        emit(PortfolioIntradayEmpty());
      } else {
        emit(PortfolioIntradayLoaded(data));
      }
      CommonLogger.info(
        'Portfolio intraday loaded: ${data.length} snapshots',
        tag: 'PortfolioIntradayCubit',
      );
    } catch (e, stack) {
      sw.stop();
      ProductTelemetry.instance.widgetTiming(
        widget: 'portfolio_intraday',
        durationMs: sw.elapsedMilliseconds,
        operation: 'fetch_error',
        technicalArea: 'portfolio',
      );
      ProductTelemetry.instance.clientError(errorType: 'portfolio_intraday');
      CommonLogger.error(
        'Failed to load portfolio intraday',
        tag: 'PortfolioIntradayCubit',
        error: e,
        stackTrace: stack,
      );
      emit(PortfolioIntradayError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
