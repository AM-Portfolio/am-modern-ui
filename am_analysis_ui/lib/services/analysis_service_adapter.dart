import 'package:am_analysis_core/am_analysis_core.dart' as core;
import '../models/analysis_models.dart' as ui;
import '../models/analysis_enums.dart';
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
    // Convert core GroupBy to UI GroupBy
    final uiGroupBy = _toUIGroupBy(groupBy);
    
    // Call the real service with the UI models
    final uiItems = await _realService.getAllocation(
      portfolioId,
      AnalysisEntityType.PORTFOLIO,
      groupBy: uiGroupBy,
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
      type: AnalysisEntityType.PORTFOLIO,
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
      AnalysisEntityType.PORTFOLIO,
      timeFrameStr,
    );
    
    // Convert UI models to core models
    return uiItems.map((item) => core.PerformanceDataPoint(
      date: item.date,
      value: item.value,
    )).toList();
  }
  
  /// Convert core GroupBy enum to UI GroupBy enum
  GroupBy _toUIGroupBy(core.GroupBy groupBy) {
    switch (groupBy) {
      case core.GroupBy.sector:
        return GroupBy.sector;
      case core.GroupBy.industry:
        return GroupBy.industry;
      case core.GroupBy.marketCap:
        return GroupBy.marketCap;
      case core.GroupBy.stock:
        return GroupBy.stock;
    }
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
