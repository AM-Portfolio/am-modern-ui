import 'package:flutter/material.dart';
import 'dart:async'; // Required for Timer-based staggered preloading of background historical base prices
import 'package:provider/provider.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:am_market_common/models/top_mover_stock.dart';
// REMOVED: import 'package:am_market_ui/shared/widgets/index_card.dart';
import 'package:am_market_ui/features/market/widgets/market_header.dart';
import 'package:am_market_ui/features/market/widgets/timeframe_selector.dart';
import 'package:am_market_ui/features/market/widgets/pinned_indices_grid.dart';
import 'package:am_market_ui/features/market/widgets/all_indices_drawer.dart';
import 'package:am_market_ui/features/market/widgets/all_indices_bottom_sheet.dart';
import '../widgets/top_movers_widget_v2.dart';
import 'package:am_market_ui/features/market_analysis/presentation/widgets/multi_index_chart.dart';
import 'package:am_market_common/services/api_service.dart';

/// User Dashboard page with API-driven features
class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> with TickerProviderStateMixin {
  late final ApiService _apiService;
  
  // Selected index for top movers (default: NIFTY 50)
  String selectedIndexForMovers = 'NIFTY 50';
  
  // Selected indices for comparison chart
  List<String> selectedIndicesForChart = ['NIFTY 50', 'NIFTY BANK'];
  
  // Top movers data
  List<TopMoverStock> topGainers = [];
  List<TopMoverStock> topLosers = [];
  bool isLoadingMovers = false;
  
  // Historical chart data
  Map<String, List<Map<String, dynamic>>> historicalData = {};
  bool isLoadingChart = false;
  String? chartError;
  String selectedTimeframe = '1D'; // Default 1D
  bool isBarChart = false; // Chart type toggle
  
  // REMOVED: final ScrollController _indicesScrollController = ScrollController();
  
  // Desktop drawer animation state
  late AnimationController _drawerController;
  bool _isDrawerVisible = false;

  // Cache for all timeframe base prices
  final Map<String, Map<String, double>> allTimeframeBasePrices = {
    '1D': {}, // Empty, since 1D uses data.pChange directly
  };
  bool isLoadingAllTimeframes = false;

  /// [SIP Optimization] Tracks which historical timeframes have been fully loaded and cached in memory.
  /// Initialized with '1D' because daily calculations are processed in real-time.
  final Set<String> _loadedTimeframes = {'1D'};

  /// [SIP Optimization] The queue of historical timeframes remaining to be preloaded in the background.
  final List<String> _preloadingQueue = ['1W', '1M', '3M', '6M', '1Y', '5Y'];

  /// [SIP Optimization] The active timer used to manage the staggered preloading intervals.
  Timer? _preloadTimer;

  /// [SIP Optimization] Indicates whether a background preloading network request is actively in-flight.
  bool _isPreloadingActive = false;

  /// [SIP Optimization] Triggers the background preloading process after a 2-second idle delay.
  /// It targets only the top 6 pinned indices that are visible in the dashboard grid,
  /// reducing the initial startup network load by 80% (from 30 symbols down to 6).
  void _triggerBasePricesLoadingIfNeeded(MarketProvider provider) {
    if (provider.allIndicesData.isNotEmpty && _preloadTimer == null && _preloadingQueue.isNotEmpty) {
      // Extract the top 6 indices that are displayed in the dashboard grid
      final pinnedSymbols = provider.allIndicesData.take(6).map((e) => e.indexSymbol).toList();
      
      // Delay the start of background fetches by 2.0 seconds. This ensures that
      // the initial page rendering and main chart data queries complete without contention.
      _preloadTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          _preloadNextInQueue(pinnedSymbols);
        }
      });
    }
  }

  /// [SIP Optimization] Recursively processes the preloading queue one timeframe at a time.
  /// Throttles API requests at a 1.5-second interval to prevent server thread exhaustion.
  Future<void> _preloadNextInQueue(List<String> symbols) async {
    if (_preloadingQueue.isEmpty || !mounted) return;

    // Retrieve the next timeframe from the queue
    final String nextTf = _preloadingQueue.first;

    // If the timeframe has already been loaded via an on-demand priority click, skip it
    if (_loadedTimeframes.contains(nextTf)) {
      _preloadingQueue.removeAt(0);
      _preloadNextInQueue(symbols);
      return;
    }

    setState(() {
      _isPreloadingActive = true;
    });

    try {
      // Fetch base prices for the single targeted timeframe
      await _loadBasePricesForTimeframe(symbols, nextTf);
      _loadedTimeframes.add(nextTf);
    } catch (e) {
      CommonLogger.error('SIP background preloader error for timeframe $nextTf', tag: 'UserDashboardPage', error: e);
    } finally {
      if (mounted) {
        setState(() {
          _isPreloadingActive = false;
          _preloadingQueue.removeAt(0);
        });

        // Schedule the next preloading task after a 1.5-second cooling period
        _preloadTimer = Timer(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _preloadNextInQueue(symbols);
          }
        });
      }
    }
  }

  /// [SIP Optimization] Executes the actual historical API request for a specific list of symbols and timeframe.
  Future<void> _loadBasePricesForTimeframe(List<String> symbols, String tf) async {
    if (symbols.isEmpty) return;

    final now = DateTime.now();
    DateTime fromDate;
    
    // Calculate the from-date based on the requested timeframe.
    // Daily historical timeframes are computed using standard lookback offsets.
    switch (tf) {
      case '1W': fromDate = now.subtract(const Duration(days: 7)); break;
      case '1M': fromDate = DateTime(now.year, now.month - 1, now.day); break;
      case '3M': fromDate = DateTime(now.year, now.month - 3, now.day); break;
      case '6M': fromDate = DateTime(now.year, now.month - 6, now.day); break;
      case '1Y': fromDate = DateTime(now.year - 1, now.month, now.day); break;
      case '5Y': fromDate = DateTime(now.year - 5, now.month, now.day); break;
      default: fromDate = now.subtract(const Duration(days: 7));
    }

    DateTime toDate;
    
    // Calculate the to-date to fetch a small window of data points at the start
    // of the timeframe to find the reference base price.
    switch (tf) {
      case '1W': toDate = fromDate.add(const Duration(days: 3)); break;
      case '1M': toDate = fromDate.add(const Duration(days: 5)); break;
      case '3M': toDate = fromDate.add(const Duration(days: 7)); break;
      case '6M': toDate = fromDate.add(const Duration(days: 7)); break;
      case '1Y': toDate = fromDate.add(const Duration(days: 10)); break;
      case '5Y': toDate = fromDate.add(const Duration(days: 10)); break;
      default: toDate = fromDate.add(const Duration(days: 3));
    }

    if (toDate.isAfter(now)) {
      toDate = now;
    }

    final fromStr = fromDate.toIso8601String().split('T')[0];
    final toStr = toDate.toIso8601String().split('T')[0];

    // Fetch the historical candles/data points from the api service
    final history = await _apiService.fetchHistoricalData(
      symbols: symbols,
      from: fromStr,
      to: toStr,
      interval: '1d',
      isIndexSymbol: true,
    );

    final Map<String, double> basePrices = {};
    if (history.containsKey('data')) {
      final dataMap = history['data'] as Map<String, dynamic>;
      dataMap.forEach((sym, val) {
        if (val is Map && val.containsKey('dataPoints')) {
          final points = List.from(val['dataPoints']);
          if (points.isNotEmpty) {
            // Find the first valid positive close price to use as the historical baseline
            for (int i = 0; i < points.length; i++) {
              final point = points[i];
              final p = point['close'] ?? point['lastPrice'] ?? point['price'];
              if (p != null && (p as num) > 0) {
                basePrices[sym] = p.toDouble();
                break;
              }
            }
          }
        }
      });
    }

    // Cache the base prices in our memory map.
    // If the map already has entries for other symbols in this timeframe, preserve them.
    if (allTimeframeBasePrices.containsKey(tf)) {
      allTimeframeBasePrices[tf]!.addAll(basePrices);
    } else {
      allTimeframeBasePrices[tf] = basePrices;
    }

    // [SIP Optimization] Push newly fetched base prices directly to the MarketProvider cache
    if (mounted) {
      context.read<MarketProvider>().updateTimeframeBasePrices(tf, basePrices);
    }
  }

  /// [SIP Optimization] Instantly triggers a prioritized, on-demand fetch of a timeframe
  /// if the user clicks a tab before the background preloader has processed it.
  /// Temporarily pauses the background preloader timer to avoid network queue congestion.
  Future<void> _loadTimeframeOnDemand(List<String> symbols, String tf) async {
    // If all target symbols are already cached for this timeframe, exit early
    final cachedForTf = allTimeframeBasePrices[tf] ?? {};
    final bool allCached = symbols.every((sym) => cachedForTf.containsKey(sym));
    if (allCached) {
      _loadedTimeframes.add(tf);
      // [SIP Optimization] Ensure the MarketProvider is in sync with our local cache when bypassing fetch
      if (mounted) {
        context.read<MarketProvider>().updateTimeframeBasePrices(tf, cachedForTf);
      }
      return;
    }

    // Pause the active staggered background preloader timer
    _preloadTimer?.cancel();

    try {
      // Perform the priority fetch for the requested symbols
      await _loadBasePricesForTimeframe(symbols, tf);
      
      // If we fetched the main pinned symbols, mark this timeframe as loaded for them
      final pinnedSymbols = context.read<MarketProvider>().allIndicesData.take(6).map((e) => e.indexSymbol).toSet();
      final bool containsAllPinned = symbols.every((sym) => pinnedSymbols.contains(sym));
      if (containsAllPinned) {
        _loadedTimeframes.add(tf);
        _preloadingQueue.remove(tf);
      }
    } catch (e) {
      CommonLogger.error('On-demand priority load error for timeframe $tf', tag: 'UserDashboardPage', error: e);
    } finally {
      if (mounted) {
        setState(() {});

        // Resume the staggered background preloading queue for remaining timeframes after a 1.5s delay
        if (_preloadingQueue.isNotEmpty) {
          final provider = context.read<MarketProvider>();
          final pinnedList = provider.allIndicesData.take(6).map((e) => e.indexSymbol).toList();
          _preloadTimer = Timer(const Duration(milliseconds: 1500), () {
            if (mounted) {
              _preloadNextInQueue(pinnedList);
            }
          });
        }
      }
    }
  }

  /// [SIP Optimization] Opens the desktop drawer and lazy-loads the base prices
  /// for the remaining 24 non-pinned indices for the current timeframe so they display correct percentages.
  void _openDrawer() {
    setState(() {
      _isDrawerVisible = true;
    });
    _drawerController.forward();
    
    // Fetch base prices for all 30 indices on-demand. Since this only requests 1 timeframe,
    // it is very lightweight and runs only when the user explicitly opens the drawer.
    final provider = context.read<MarketProvider>();
    final allSymbols = provider.allIndicesData.map((e) => e.indexSymbol).toList();
    _loadTimeframeOnDemand(allSymbols, selectedTimeframe);
  }

  void _closeDrawer() {
    _drawerController.reverse();
  }

  /// [SIP Optimization] Opens the mobile bottom sheet and lazy-loads the base prices
  /// for all 30 indices for the current timeframe so they display correct percentages.
  void _showMobileAllIndicesBottomSheet(BuildContext context, MarketProvider provider) {
    // Fetch base prices for all 30 indices on-demand. Since this only requests 1 timeframe,
    // it is very lightweight and runs only when the user explicitly opens the bottom sheet.
    final allSymbols = provider.allIndicesData.map((e) => e.indexSymbol).toList();
    _loadTimeframeOnDemand(allSymbols, selectedTimeframe);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x8C000000),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (context, scrollController) => AllIndicesBottomSheet(
          scrollController: scrollController,
          initialTimeframe: selectedTimeframe,
          indices: provider.allIndicesData,
          selectedIndexSymbol: selectedIndexForMovers,
          onIndexSelected: (data) {
            setState(() {
              selectedIndexForMovers = data.indexSymbol;
            });
            _loadTopMovers();
            Navigator.pop(context);
          },
          allTimeframeBasePrices: allTimeframeBasePrices,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // REMOVED: _indicesScrollController.dispose();
    // [SIP Optimization] Cancel the background preloading timer to prevent memory leaks or state updates after widget disposal.
    _preloadTimer?.cancel();
    _drawerController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    
    _drawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _drawerController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        if (mounted) {
          setState(() {
            _isDrawerVisible = false;
          });
        }
      }
    });

    // Load initial data
    Future.delayed(Duration.zero, () {
      _loadTopMovers();
      _loadHistoricalData();
      if (mounted) {
        final provider = context.read<MarketProvider>();
        provider.setIndicesTimeframe(selectedTimeframe);
        _triggerBasePricesLoadingIfNeeded(provider);
      }
    });
  }

  /// Load top gainers and losers for selected index
  Future<void> _loadTopMovers() async {
    if (!mounted) return;
    
    setState(() {
      isLoadingMovers = true;
    });

    try {
      // Unified call for both gainers and losers
      final unifiedData = await _apiService.fetchMoversUnified(
        limit: 5,
        indexSymbol: selectedIndexForMovers,
        timeFrame: selectedTimeframe,
      );
      
      if (!mounted) return;
      
      setState(() {
        topGainers = (unifiedData['gainers'] ?? []).map((e) => TopMoverStock.fromJson(e)).toList();
        topLosers = (unifiedData['losers'] ?? []).map((e) => TopMoverStock.fromJson(e)).toList();
        isLoadingMovers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingMovers = false;
      });
      CommonLogger.error('Error loading top movers', tag: 'UserDashboardPage', error: e);
    }
  }

  /// Load historical data for selected indices
  Future<void> _loadHistoricalData() async {
    if (!mounted) return;
    
    setState(() {
      isLoadingChart = true;
      chartError = null;
    });

    try {
      final data = await _apiService.fetchHistoryBatch(selectedIndicesForChart, selectedTimeframe);

      if (!mounted) return;
      
      setState(() {
        historicalData = data;
        isLoadingChart = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        chartError = 'Failed to load chart data';
        isLoadingChart = false;
      });
      CommonLogger.error('Error loading historical data', tag: 'UserDashboardPage', error: e);
    }
  }

  void _showAddIndexDialog(MarketProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Compare Indices', style: TextStyle(color: Colors.white)),
              backgroundColor: const Color(0xFF1E293B),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: ListView.builder(
                  itemCount: provider.allIndicesData.length,
                  itemBuilder: (context, index) {
                    final data = provider.allIndicesData[index];
                    final isSelected = selectedIndicesForChart.contains(data.indexSymbol);
                    return CheckboxListTile(
                      title: Text(data.indexSymbol, style: const TextStyle(color: Colors.white)),
                      value: isSelected,
                      activeColor: const Color(0xFF00D1FF),
                      checkColor: Colors.black,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            if (selectedIndicesForChart.length < 5) {
                              selectedIndicesForChart.add(data.indexSymbol);
                            }
                          } else {
                            if (selectedIndicesForChart.length > 1) {
                              selectedIndicesForChart.remove(data.indexSymbol);
                            }
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Start reload
                    _loadHistoricalData();
                    // Parent setState to reflect changes if needed
                    this.setState(() {}); 
                  },
                  child: const Text('Done', style: TextStyle(color: Color(0xFF00D1FF))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<MarketProvider>(
      builder: (context, provider, _) {
        // Loading state
        if (provider.isLoading && provider.allIndicesData.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF00D1FF),
            ),
          );
        }

        // Trigger pre-fetching of base prices if needed
        _triggerBasePricesLoadingIfNeeded(provider);

        // Main content
        return Stack(
          children: [
            Container(
              decoration: AppGlassmorphismV2.techBackground(isDark: isDark),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Section
                    MarketHeader(
                      selectedTimeframe: selectedTimeframe,
                      onTimeframeChanged: (tf) {
                        setState(() {
                          selectedTimeframe = tf;
                        });
                        provider.setIndicesTimeframe(tf);
                        _loadHistoricalData();
                        _loadTopMovers();
                        
                        // [SIP Optimization] Immediately prioritize fetching base prices for the visible pinned cards
                        // when the user selects a new timeframe tab, ensuring instant card updates.
                        final pinnedSymbols = provider.allIndicesData.take(6).map((e) => e.indexSymbol).toList();
                        _loadTimeframeOnDemand(pinnedSymbols, tf);
                      },
                      onAllIndicesPressed: () {
                        if (MediaQuery.of(context).size.width < 768) {
                          _showMobileAllIndicesBottomSheet(context, provider);
                        } else {
                          _openDrawer();
                        }
                      },
                    ),

                    /* // REMOVED:
                    InfoLayerCard(
                      title: 'Market Dashboard',
                      subtitle: 'Real-time market overview',
                      icon: Icons.dashboard_rounded,
                      colorScheme: 'primary',
                    ),
                    */
                    
                    const SizedBox(height: 24),

                    if (MediaQuery.of(context).size.width < 768) ...[
                      TimeframeSelector(
                        selectedTimeframe: selectedTimeframe,
                        onTimeframeChanged: (tf) {
                          setState(() {
                            selectedTimeframe = tf;
                          });
                          provider.setIndicesTimeframe(tf);
                          _loadHistoricalData();
                          _loadTopMovers();
                          
                          // [SIP Optimization] Immediately prioritize fetching base prices for the visible pinned cards
                          // when the user selects a new timeframe tab, ensuring instant card updates.
                          final pinnedSymbols = provider.allIndicesData.take(6).map((e) => e.indexSymbol).toList();
                          _loadTimeframeOnDemand(pinnedSymbols, tf);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Pinned Index Cards Grid
                    PinnedIndicesGrid(
                      indices: provider.allIndicesData,
                      selectedIndexSymbol: selectedIndexForMovers,
                      onIndexSelected: (data) {
                        setState(() {
                          selectedIndexForMovers = data.indexSymbol;
                        });
                        _loadTopMovers();
                      },
                    ),

                    /* // REMOVED:
                    // Index Cards Carousel  
                    SizedBox(
                      height: 156, // Increased height to accommodate scrollbar
                      child: RawScrollbar(
                        controller: _indicesScrollController,
                        thumbVisibility: true,
                        thumbColor: const Color(0xFF00D1FF).withOpacity(0.5),
                        radius: const Radius.circular(8),
                        thickness: 6,
                        padding: const EdgeInsets.only(bottom: 2),
                        child: ListView.builder(
                          controller: _indicesScrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: provider.allIndicesData.length,
                          itemBuilder: (context, index) {
                            final data = provider.allIndicesData[index];
                            final isSelected = data.indexSymbol == selectedIndexForMovers;
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedIndexForMovers = data.indexSymbol;
                                });
                                _loadTopMovers();
                              },
                              child: Container(
                                decoration: isSelected
                                    ? BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF00D1FF),
                                          width: 2,
                                        ),
                                      )
                                    : null,
                                child: IndexCard(data: data),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    */
                    
                    const SizedBox(height: 32),

                    /* // REMOVED:
                    // --- GLOBAL FILTER BAR ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Timeframe: ',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 12, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: ['1D', '1W', '1M', '3M', '6M', '1Y', '5Y'].map((tf) {
                              final isSelected = tf == selectedTimeframe;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedTimeframe = tf;
                                  });
                                  provider.setIndicesTimeframe(tf);
                                  _loadHistoricalData();
                                  _loadTopMovers();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF00D1FF).withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    tf,
                                    style: TextStyle(
                                      color: isSelected ? const Color(0xFF00D1FF) : Colors.white.withOpacity(0.6),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    */
                    
                    const SizedBox(height: 24),

                // --- INDICES COMPARISON SECTION (Moved Up) ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'INDICES COMPARISON',
                          style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black45,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        // Chart Controls
                        Row(
                          children: [
                            // Toggle Chart Type
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.show_chart, 
                                        color: !isBarChart ? const Color(0xFF00D1FF) : Colors.white54,
                                        size: 20),
                                    onPressed: () => setState(() => isBarChart = false),
                                    tooltip: 'Line Chart',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.bar_chart, 
                                        color: isBarChart ? const Color(0xFF00D1FF) : Colors.white54,
                                        size: 20),
                                    onPressed: () => setState(() => isBarChart = true),
                                    tooltip: 'Bar Chart',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Add Index Button
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00D1FF)),
                              onPressed: () => _showAddIndexDialog(provider),
                              tooltip: 'Add Index',
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Multi-Index Chart
                    SizedBox(
                      height: 400,
                      child: MultiIndexChart(
                        historicalData: historicalData,
                        selectedIndices: selectedIndicesForChart,
                        isLoading: isLoadingChart,
                        error: chartError,
                        isBarChart: isBarChart,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
                
                // --- TOP MOVERS SECTION (Moved Down) ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'TOP MOVERS',
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black45,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D1FF).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                selectedIndexForMovers,
                                style: const TextStyle(
                                  color: Color(0xFF00D1FF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        // Move info hint
                        Text(
                          'Based on $selectedTimeframe',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TopMoversWidgetV2(
                            movers: topGainers,
                            title: 'Top Gainers',
                            isGainers: true,
                            isLoading: isLoadingMovers,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TopMoversWidgetV2(
                            movers: topLosers,
                            title: 'Top Losers',
                            isGainers: false,
                            isLoading: isLoadingMovers,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
              ],
            ),
          ),
        ),

        // Drawer Overlay (semi-transparent background)
        if (_isDrawerVisible)
          Positioned.fill(
            child: FadeTransition(
              opacity: _drawerController,
              child: GestureDetector(
                onTap: _closeDrawer,
                child: Container(
                  color: const Color(0x80000000), // rgba(0,0,0,0.50)
                ),
              ),
            ),
          ),

        // Drawer Container (slides in from right)
        if (_isDrawerVisible)
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _drawerController,
                  curve: Curves.easeOut,
                  reverseCurve: Curves.easeIn,
                ),
              ),
              child: AllIndicesDrawer(
                indices: provider.allIndicesData,
                initialTimeframe: selectedTimeframe,
                selectedIndexSymbol: selectedIndexForMovers,
                onIndexSelected: (data) {
                  setState(() {
                    selectedIndexForMovers = data.indexSymbol;
                  });
                  _loadTopMovers();
                  _closeDrawer();
                },
                onClose: _closeDrawer,
                allTimeframeBasePrices: allTimeframeBasePrices,
              ),
            ),
          ),
      ],
    );
  },
);
}
}
