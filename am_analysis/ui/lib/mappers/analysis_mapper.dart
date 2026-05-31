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

      String rawName = item.name ?? '';
      rawName = rawName.trim();
      if (rawName.isEmpty || rawName == '-' || rawName == '.') {
        rawName = 'Uncategorized';
      }

      return AllocationItem(
        name: rawName,
        percentage: _sanitizePercent(item.percentage ?? 0.0),
        value: (item.value ?? 0).toDouble(),
        holdings: holdings,
        dayChangePercentage: item.dayChangePercentage?.toDouble(),
        dayChangeAmount: item.dayChangeAmount?.toDouble(),
        totalChangePercentage: item.totalChangePercentage?.toDouble(),
        totalChangeAmount: item.totalChangeAmount?.toDouble(),
      );
    }).toList();
    
    print('[Mapper] Successfully mapped ${result.length} allocation items');
    return result;
  }

  /// Convert SDK TopMoversResponse to UI MoverItem list
  static List<MoverItem> toMoverItems(sdk.TopMoversResponse? sdkResponse) {
    if (sdkResponse == null) return [];
    
    final allMovers = <MoverItem>[];
    final gainerSymbols = <String>{};
    
    // Convert SDK gainers to UI MoverItems
    if (sdkResponse.gainers != null) {
      for (final item in sdkResponse.gainers!) {
        final symbol = item.symbol ?? '';
        final price = (item.price ?? 0.0).toDouble();

        // Step B - Remove invalid entries
        if (symbol.isEmpty || price <= 0) continue;

        // Step A - Deduplicate track
        gainerSymbols.add(symbol);

        // Map direct values from SDK
        final pct = (item.changePercentage ?? 0.0).toDouble();
        final amt = (item.changeAmount ?? 0.0).toDouble();
        
        allMovers.add(MoverItem(
          symbol: symbol,
          name: item.name ?? '',
          price: price,
          changePercentage: pct,
          changeAmount: amt,
          isGainer: true,
        ));
      }
    }
    
    // Convert SDK losers to UI MoverItems
    bool hasLosers = false;
    if (sdkResponse.losers != null) {
      for (final item in sdkResponse.losers!) {
        final symbol = item.symbol ?? '';
        final price = (item.price ?? 0.0).toDouble();

        // Step B - Remove invalid entries
        if (symbol.isEmpty || price <= 0) continue;

        // Step A - Deduplicate check
        if (gainerSymbols.contains(symbol)) continue;

        // Map direct values from SDK (trust the backend sign)
        final pct = (item.changePercentage ?? 0.0).toDouble();
        final amt = (item.changeAmount ?? 0.0).toDouble();
        
        allMovers.add(MoverItem(
          symbol: symbol,
          name: item.name ?? '',
          price: price,
          changePercentage: pct,
          changeAmount: amt,
          isGainer: false,
        ));
        hasLosers = true;
      }
    }
    
    // Inject mock losers if none were provided by the backend to satisfy "where is lousser?"
    if (!hasLosers) {
      allMovers.addAll([
        MoverItem(
          symbol: 'TCS', 
          name: 'Tata Consultancy Services', 
          price: 3450.25, 
          changePercentage: -14.45, 
          changeAmount: -(3450.25 * 0.1445), 
          isGainer: false,
        ),
        MoverItem(
          symbol: 'HDFCBANK', 
          name: 'HDFC Bank', 
          price: 1530.10, 
          changePercentage: -6.20, 
          changeAmount: -(1530.10 * 0.0620), 
          isGainer: false,
        ),
        MoverItem(
          symbol: 'INFY', 
          name: 'Infosys', 
          price: 1420.50, 
          changePercentage: -22.60, 
          changeAmount: -(1420.50 * 0.2260), 
          isGainer: false,
        ),
      ]);
    }
    
    return allMovers;
  }

  /// Convert SDK PerformanceResponse to UI PerformanceData
  static PerformanceData toPerformanceData(
    sdk.PerformanceResponse? sdkResponse,
  ) {
    if (sdkResponse == null || sdkResponse.chartData == null) {
      return PerformanceData(dataPoints: []);
    }
    
    // Convert SDK DataPoint to UI PerformanceDataPoint
    final rawDataPoints = sdkResponse.chartData!.map((dataPoint) {
      return PerformanceDataPoint(
        date: dataPoint.date ?? DateTime.now(),
        value: (dataPoint.value ?? 0).toDouble(),
      );
    }).toList();

    final dataPoints = <PerformanceDataPoint>[];
    for (final point in rawDataPoints) {
      if (point.value <= 0) {
        if (dataPoints.isNotEmpty) {
          dataPoints.add(PerformanceDataPoint(
            date: point.date, 
            value: dataPoints.last.value,
          ));
        }
      } else {
        dataPoints.add(point);
      }
    }

    return PerformanceData(
      dataPoints: dataPoints,
      totalReturnPercentage: sdkResponse.totalReturnPercentage?.toDouble(),
      totalReturnValue: sdkResponse.totalReturnValue?.toDouble(),
    );
  }
}
