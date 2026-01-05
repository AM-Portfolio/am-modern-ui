import 'package:equatable/equatable.dart';
import '../../../internal/domain/entities/report/daily_performance.dart';
import '../../../internal/domain/entities/report/timing_analysis.dart';
import '../../../internal/domain/entities/report/trade_performance_summary.dart';

abstract class TradeReportState extends Equatable {
  const TradeReportState();

  @override
  List<Object?> get props => [];
}

class TradeReportInitial extends TradeReportState {}

class TradeReportLoading extends TradeReportState {}

class TradeReportLoaded extends TradeReportState {
  final TradePerformanceSummary summary;
  final List<DailyPerformance> dailyPerformance;
  final TimingAnalysis timingAnalysis;

  const TradeReportLoaded({
    required this.summary,
    required this.dailyPerformance,
    required this.timingAnalysis,
  });

  @override
  List<Object?> get props => [summary, dailyPerformance, timingAnalysis];
}

class TradeReportError extends TradeReportState {
  final String message;

  const TradeReportError(this.message);

  @override
  List<Object?> get props => [message];
}
