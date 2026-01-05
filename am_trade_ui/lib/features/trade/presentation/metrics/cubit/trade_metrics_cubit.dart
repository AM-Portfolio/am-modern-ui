import '../../../internal/domain/enums/metric_types.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../internal/domain/entities/metrics/metrics_filter_request.dart';
import '../../../internal/domain/usecases/get_trade_metrics.dart';
import '../../../internal/domain/usecases/get_metric_types.dart';
import 'trade_metrics_state.dart';

class TradeMetricsCubit extends Cubit<TradeMetricsState> {
  final GetTradeMetrics getTradeMetrics;
  final GetMetricTypes getMetricTypes;
  List<MetricTypes> _cachedMetricTypes = [];

  TradeMetricsCubit({
    required this.getTradeMetrics,
    required this.getMetricTypes,
  }) : super(TradeMetricsInitial());

  Future<void> loadMetrics(MetricsFilterRequest filter) async {
    emit(TradeMetricsLoading());
    try {
      if (_cachedMetricTypes.isEmpty) {
        _cachedMetricTypes = await getMetricTypes();
      }
      
      final metrics = await getTradeMetrics(filter);
      emit(TradeMetricsLoaded(
        metrics: metrics,
        filter: filter,
        availableMetricTypes: _cachedMetricTypes,
      ));
    } catch (e) {
      emit(TradeMetricsError(e.toString()));
    }
  }

  Future<void> refreshMetrics() async {
    if (state is TradeMetricsLoaded) {
      final currentState = state as TradeMetricsLoaded;
      try {
        final metrics = await getTradeMetrics(currentState.filter);
        emit(TradeMetricsLoaded(
          metrics: metrics,
          filter: currentState.filter,
          availableMetricTypes: currentState.availableMetricTypes.isNotEmpty 
              ? currentState.availableMetricTypes 
              : _cachedMetricTypes,
        ));
      } catch (e) {
        emit(TradeMetricsError(e.toString()));
      }
    }
  }

  void updateFilter(MetricsFilterRequest newFilter) {
    loadMetrics(newFilter);
  }
}
