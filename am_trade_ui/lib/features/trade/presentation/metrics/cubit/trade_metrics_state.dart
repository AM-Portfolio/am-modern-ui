import 'package:equatable/equatable.dart';
import '../../../internal/domain/entities/metrics/trade_metrics_response.dart';
import '../../../internal/domain/entities/metrics/metrics_filter_request.dart';
import '../../../internal/domain/enums/metric_types.dart';

abstract class TradeMetricsState extends Equatable {
  const TradeMetricsState();

  @override
  List<Object?> get props => [];
}

class TradeMetricsInitial extends TradeMetricsState {}

class TradeMetricsLoading extends TradeMetricsState {}

class TradeMetricsLoaded extends TradeMetricsState {
  final TradeMetricsResponse metrics;
  final MetricsFilterRequest filter;

  const TradeMetricsLoaded({
    required this.metrics,
    required this.filter,
    this.availableMetricTypes = const [],
  });
  
  final List<MetricTypes> availableMetricTypes;

  @override
  List<Object?> get props => [metrics, filter, availableMetricTypes];
}

class TradeMetricsError extends TradeMetricsState {
  final String message;

  const TradeMetricsError(this.message);

  @override
  List<Object?> get props => [message];
}
