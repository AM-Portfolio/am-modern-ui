import 'package:am_analysis_core/am_analysis_core.dart' as core;
import 'package:am_analysis_core/am_analysis_core.dart' as ui;
import 'package:am_analysis_core/models/enums.dart' as core_enums;
import '../config/analysis_config.dart';
import './real_analysis_service.dart';

/// Adapter that converts am_analysis_ui's RealAnalysisService to implement
/// the am_analysis_core's AnalysisService interface.
/// 
/// This enables the core Cubits to use the existing service implementation.
class AnalysisServiceAdapter implements core.AnalysisService {
  final RealAnalysisService _realService;
  
  AnalysisServiceAdapter(this._realService);
  
  @override
  Future<List<core.AllocationItem>> getAllocation({
    required String portfolioId,
    required core.GroupBy groupBy,
  }) async {
    // Call the real service with the UI models
    final uiItems = await _realService.getAllocation(
      portfolioId,
      core.AnalysisEntityType.PORTFOLIO,
      groupBy: groupBy,
    );
    
    // Convert UI models to core models
    return uiItems.map((item) => core.AllocationItem(
      name: item.name,
      percentage: item.percentage,
      value: item.value,
    )).toList();
  }
  
  @override
  Future<List<core.MoverItem>> getTopMovers({
    required String portfolioId,
    required core.TimeFrame timeFrame,
  }) async {
    // Convert core TimeFrame to string for API
    final timeFrameStr = _toTimeFrameString(timeFrame);
    
    // Call the real service
    final uiItems = await _realService.getTopMovers(
      id: portfolioId,
      type: core.AnalysisEntityType.PORTFOLIO,
      timeFrame: timeFrameStr,
    );
    
    // Convert UI models to core models
    return uiItems.map((item) => core.MoverItem(
      symbol: item.symbol,
      name: item.name,
      price: item.price,
      changePercentage: item.changePercentage,
      changeAmount: item.changeAmount,
    )).toList();
  }
  
  @override
  Future<List<core.PerformanceDataPoint>> getPerformance({
    required String portfolioId,
    required core.TimeFrame timeFrame,
  }) async {
    // Convert core TimeFrame to string for API
    final timeFrameStr = _toTimeFrameString(timeFrame);
    
    // Call the real service
    final uiItems = await _realService.getPerformance(
      portfolioId,
      core.AnalysisEntityType.PORTFOLIO,
      timeFrameStr,
    );
    
    // Convert UI models to core models
    return uiItems.map((item) => core.PerformanceDataPoint(
      date: item.date,
      value: item.value,
    )).toList();
  }
  
  /// Convert core TimeFrame enum to string for API
  String _toTimeFrameString(core.TimeFrame timeFrame) {
    switch (timeFrame) {
      case core.TimeFrame.oneDay:
        return '1D';
      case core.TimeFrame.oneWeek:
        return '1W';
      case core.TimeFrame.oneMonth:
        return '1M';
      case core.TimeFrame.threeMonths:
        return '3M';
      case core.TimeFrame.oneYear:
        return '1Y';
      case core.TimeFrame.all:
        return 'ALL';
    }
  }
}
