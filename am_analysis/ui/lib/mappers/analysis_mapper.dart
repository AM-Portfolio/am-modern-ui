import 'package:am_analysis_sdk/api.dart' as sdk;
import 'package:am_analysis_core/am_analysis_core.dart';

/// Mapper to convert SDK models to UI models
class AnalysisMapper {
  /// Backend sends allocation percentages on a 0–100 scale; guard non-finite values.
  static double _sanitizePercent(double value) {
    if (!value.isFinite) return 0.0;
    return value;
  }
  /// Convert SDK AllocationResponse to UI AllocationItem list based on groupBy
  static List<AllocationItem> toAllocationItems(
    sdk.AllocationResponse? sdkResponse,
    GroupBy groupBy,
  ) {
    print('[Mapper] toAllocationItems called with groupBy=$groupBy');
    print('[Mapper] SDK Response: sectors=${sdkResponse?.sectors.length}, assetClasses=${sdkResponse?.assetClasses.length}, marketCaps=${sdkResponse?.marketCaps.length}, stocks=${sdkResponse?.stocks.length}');
    
    if (sdkResponse == null) {
      print('[Mapper] SDK Response is null!');
      return [];
    }
    
    // Select the appropriate list based on groupBy
    List<sdk.AllocationItem>? sdkItems;
    switch (groupBy) {
      case GroupBy.sector:
        sdkItems = sdkResponse.sectors;
        break;
      case GroupBy.industry:
        sdkItems = sdkResponse.assetClasses; // Using assetClasses as proxy
        break;
      case GroupBy.marketCap:
        sdkItems = sdkResponse.marketCaps;
        break;
      case GroupBy.stock:
        sdkItems = sdkResponse.stocks;
        break;
    }
    
    if (sdkItems == null || sdkItems.isEmpty) {
      print('[Mapper] Selected items for $groupBy is null or empty');
      return [];
    }
    
    print('[Mapper] Mapping ${sdkItems.length} items for $groupBy');
    // Convert SDK AllocationItem to UI AllocationItem
    final result = sdkItems.map((item) {
      List<AllocationHolding>? holdings;
      // Check if item has holdings (it might be dynamic or specific subclass)
      try {
        // Attempt to access holdings if available in the SDK model
        // We use dynamic access or check if the generated model supports it
        // Assuming SDK has been updated to include holdings in AllocationItem
        if (item.holdings != null) {
          holdings = item.holdings!.map((h) => AllocationHolding(
            symbol: h.symbol ?? '',
            name: h.name ?? '',
            value: (h.value ?? 0).toDouble(),
            percentage: _sanitizePercent((h.percentage ?? 0).toDouble()),
            portfolioPercentage: _sanitizePercent((h.portfolioPercentage ?? 0).toDouble()),
          )).toList();
        }
      } catch (e) {
        // Ignore if holdings not present or accessible
        print('[Mapper] Error mapping holdings: $e');
      }

      return AllocationItem(
        name: item.name ?? 'Unknown',
        percentage: _sanitizePercent(item.percentage ?? 0.0),
        value: (item.value ?? 0).toDouble(),
        holdings: holdings,
      );
    }).toList();
    
    print('[Mapper] Successfully mapped ${result.length} allocation items');
    return result;
  }

  /// Convert SDK TopMoversResponse to UI MoverItem list
  static List<MoverItem> toMoverItems(sdk.TopMoversResponse? sdkResponse) {
    if (sdkResponse == null) return [];
    
    final allMovers = <MoverItem>[];
    
    // Convert SDK gainers to UI MoverItems
    if (sdkResponse.gainers != null) {
      allMovers.addAll(sdkResponse.gainers!.map((item) {
        // Ensure gainer percentage is positive
        final percentage = (item.changePercentage ?? 0.0).abs();
        final amount = (item.changeAmount ?? 0.0).toDouble().abs();
        
        return MoverItem(
          symbol: item.symbol ?? '',
          name: item.name ?? '',
          price: (item.price ?? 0.0).toDouble(),
          changePercentage: percentage,
          changeAmount: amount,
          isGainer: true,
        );
      }));
    }
    
    // Convert SDK losers to UI MoverItems
    if (sdkResponse.losers != null) {
      allMovers.addAll(sdkResponse.losers!.map((item) {
        // Ensure loser percentage is negative
        final percentage = -(item.changePercentage ?? 0.0).abs();
        final amount = -(item.changeAmount ?? 0.0).toDouble().abs();
        
        return MoverItem(
          symbol: item.symbol ?? '',
          name: item.name ?? '',
          price: (item.price ?? 0.0).toDouble(),
          changePercentage: percentage,
          changeAmount: amount,
          isGainer: false,
        );
      }));
    }
    
    return allMovers;
  }

  /// Convert SDK PerformanceResponse to UI PerformanceDataPoint list
  static List<PerformanceDataPoint> toPerformanceDataPoints(
    sdk.PerformanceResponse? sdkResponse,
  ) {
    if (sdkResponse == null || sdkResponse.chartData == null) return [];
    
    // Convert SDK DataPoint to UI PerformanceDataPoint
    return sdkResponse.chartData!.map((dataPoint) {
      return PerformanceDataPoint(
        date: dataPoint.date ?? DateTime.now(),
        value: (dataPoint.value ?? 0).toDouble(),
      );
    }).toList();
  }
}
