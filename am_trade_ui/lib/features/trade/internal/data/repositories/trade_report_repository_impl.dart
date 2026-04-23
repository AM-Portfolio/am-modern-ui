import 'package:am_common/am_common.dart';
import '../../domain/entities/metrics/metrics_filter_request.dart';
import '../../domain/entities/report/daily_performance.dart';
import '../../domain/entities/report/timing_analysis.dart';
import '../../domain/entities/report/trade_performance_summary.dart';
import '../../domain/repositories/trade_report_repository.dart';
import '../datasources/trade_report_remote_datasource.dart';
import '../dtos/metrics/metrics_dtos.dart';
import '../mappers/trade_report_mapper.dart';

class TradeReportRepositoryImpl implements TradeReportRepository {
  final TradeReportRemoteDataSource remoteDataSource;

  TradeReportRepositoryImpl(this.remoteDataSource);

  @override
  Future<TradePerformanceSummary> getPerformanceSummary(MetricsFilterRequest filter) async {
    AppLogger.debug('Repo: Requesting Summary', tag: 'TradeReportRepository');
    final filterDto = MetricsFilterRequestDto.fromEntity(filter);
    final responseDto = await remoteDataSource.getSummary(filterDto);
    AppLogger.debug('Repo: Summary DTO received: ${responseDto.totalTrades} trades', tag: 'TradeReportRepository');
    return TradeReportMapper.toSummary(responseDto);
  }

  @override
  Future<List<DailyPerformance>> getDailyPerformance(MetricsFilterRequest filter) async {
    AppLogger.debug('Repo: Requesting Daily', tag: 'TradeReportRepository');
    final filterDto = MetricsFilterRequestDto.fromEntity(filter);
    final responseDtos = await remoteDataSource.getDaily(filterDto);
    AppLogger.debug('Repo: Daily DTOs received: ${responseDtos.length} items', tag: 'TradeReportRepository');
    final entities = responseDtos.map((e) => TradeReportMapper.toDaily(e)).toList();
    AppLogger.debug('Repo: Daily Entities mapped successfully', tag: 'TradeReportRepository');
    return entities;
  }

  @override
  Future<TimingAnalysis> getTimingAnalysis(MetricsFilterRequest filter) async {
    AppLogger.debug('Repo: Requesting Timing', tag: 'TradeReportRepository');
    final filterDto = MetricsFilterRequestDto.fromEntity(filter);
    final responseDto = await remoteDataSource.getTiming(filterDto);
    AppLogger.debug('Repo: Timing DTO received', tag: 'TradeReportRepository');
    return TradeReportMapper.toTimingAnalysis(responseDto);
  }
}

