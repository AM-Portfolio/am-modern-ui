import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:am_design_system/am_design_system.dart';
import '../models/market_data.dart';
import '../models/available_indices.dart';
import '../models/indices_region.dart';
import '../models/historical_performance_model.dart';
import '../models/seasonality_model.dart';
import '../services/api_service.dart';
import '../data/repositories/market_data_repository.dart';

import 'package:am_common/core/services/price_service.dart';
import 'package:am_common/core/models/price_update_model.dart';

/// Market shell / module tabs that are not index symbols — never call
/// [MarketProvider.refreshIndexData] / `fetchIndexData` for these.
@visibleForTesting
const Set<String> kMarketNavigationOnlySelections = {
  'Streamer',
  'Instrument Explorer',
  'Security Explorer',
  'Price Test',
  'ETF Explorer',
  'Admin Dashboard',
  'Analysis Dashboard',
  'Developer Dashboard',
  'Market Analysis',
  'Heatmap',
  'Heatmap Explorer',
  // User-mode tabs (must stay in sync with dashboard_page titles)
  'Paper',
  'Watch List',
  'Watchlist',
  'Equity Insider',
  'Futures & Options',
  'IPO Center',
  'IPO',
};

class MarketProvider with ChangeNotifier {
  ApiService? _apiServiceOrNull;
  final MarketDataRepository? _repository;

  /// Lazily created so unit tests that never hit the network avoid GetIt.
  ApiService get _apiService => _apiServiceOrNull ??= ApiService();

  /// Test-only override for sparkline history fetches.
  @visibleForTesting
  Future<Map<String, List<Map<String, dynamic>>>> Function(
    List<String> symbols,
    String range,
  )? debugHistoryBatchFetcher;

  MarketProvider({
    MarketDataRepository? repository,
    ApiService? apiService,
  })  : _repository = repository,
        _apiServiceOrNull = apiService;

  /// True when [title] is a Market UI tab, not an index symbol.
  static bool isNavigationOnlySelection(String? title) {
    if (title == null || title.isEmpty) return false;
    return kMarketNavigationOnlySelections.contains(title);
  }

  AvailableIndices? _availableIndices;
  StockIndicesMarketData? _currentIndexData;
  List<StockIndicesMarketData> _allIndicesData = []; // Indian Market Overview
  List<StockIndicesMarketData> _globalIndicesData = [];
  IndicesRegion _indicesRegion = IndicesRegion.indian;

  String? _selectedIndex;
  bool _isLoading = false;
  String? _error;
  bool _forceRefresh = false; // "Force Refresh" toggle state
  bool _indexSymbol =
      true; // True = fetch index data only, False = expand to constituents

  // Theme Management removed - moved to am_common_ui ThemeCubit

  // PriceService Integration
  PriceService? _priceService;
  final Set<String> _subscribedSymbols = {};
  static const int _maxLiveStreamSymbols = 20;
  DateTime? _lastNotify;
  static const Duration _notifyThrottle = Duration(milliseconds: 300);
  StreamSubscription<MarketDataUpdate>? _priceUpdateSub;

  void setPriceService(PriceService service) {
    if (_priceService == service) {
      unawaited(_resubscribeActiveSymbols());
      return;
    }
    _priceUpdateSub?.cancel();
    _priceService = service;
    CommonLogger.info("PriceService delegated to MarketProvider",
        tag: "MarketProvider");

    _syncWithPriceService();

    _priceUpdateSub = _priceService!.updateStream.listen((update) {
      if (update.quotes != null) {
        update.quotes!.forEach((symbol, quote) {
          final data = quote.toJson();
          data['symbol'] = symbol;
          _processSingleUpdate(symbol, data);
        });
      }
    });

    unawaited(_resubscribeActiveSymbols());
  }

  Future<void> _resubscribeActiveSymbols() async {
    if (_priceService == null) return;

    final symbols = <String>{..._subscribedSymbols};
    if (symbols.isEmpty) {
      symbols.addAll(_priceService!.subscribedSymbols);
    }
    if (_selectedIndex != null &&
        _selectedIndex != 'All Indices' &&
        _selectedIndex != 'Dashboard' &&
        !isNavigationOnlySelection(_selectedIndex)) {
      symbols.add(_selectedIndex!);
    }
    if (_allIndicesData.isNotEmpty) {
      symbols.addAll(_allIndicesData.map((e) => e.indexSymbol));
    }
    if (symbols.isEmpty) return;

    await _priceService!.subscribe(
      symbols.toList(),
      isIndexSymbol: _indexSymbol,
      forceResubscribe: true,
    );
    _subscribedSymbols
      ..clear()
      ..addAll(symbols.take(_maxLiveStreamSymbols));
  }

  Future<void> _ensurePriceSubscription(List<String> symbols) async {
    if (_priceService == null || symbols.isEmpty) return;

    final room = _maxLiveStreamSymbols - _subscribedSymbols.length;
    if (room <= 0) {
      CommonLogger.info(
        'Live stream cap reached ($_maxLiveStreamSymbols symbols) — not adding more',
        tag: 'MarketProvider._ensurePriceSubscription',
      );
      return;
    }

    final pending = symbols
        .where((s) => !_subscribedSymbols.contains(s))
        .take(room)
        .toList();
    if (pending.isEmpty) return;

    await _priceService!.subscribe(pending, isIndexSymbol: _indexSymbol);
    _subscribedSymbols.addAll(pending);
    CommonLogger.info(
      'Subscribed to ${pending.length} symbols (${_subscribedSymbols.length}/$_maxLiveStreamSymbols active)',
      tag: 'MarketProvider._ensurePriceSubscription',
    );
  }

  Future<void> _releasePriceSubscription() async {
    if (_priceService == null || _subscribedSymbols.isEmpty) return;
    final symbols = _subscribedSymbols.toList();
    await _priceService!.unsubscribe(symbols);
    _subscribedSymbols.clear();
    CommonLogger.info(
      'Unsubscribed from ${symbols.length} market symbols',
      tag: 'MarketProvider._releasePriceSubscription',
    );
  }

  // Legacy Store Support (if needed, or just defer to PriceService)
  // We keep _livePrices as a local cache only if PriceService is null (fallback)
  // But ideally we read from PriceService.

  // Stream is now from PriceService
  Stream<Map<String, dynamic>> get livePriceStream {
    if (_priceService != null) {
      return _priceService!.priceStream.map((quotes) {
        return quotes.map((key, value) => MapEntry(key, value.toJson()));
      });
    }
    return _livePriceController.stream;
  }

  // Internal Fallback State (initialized if PriceService unavailable)
  final Map<String, Map<String, dynamic>> _internalLivePrices = {};
  final StreamController<Map<String, dynamic>> _livePriceController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Legacy Store Support
  Map<String, Map<String, dynamic>> get livePrices {
    return _internalLivePrices;
  }

  // Unified Price Getter
  Map<String, dynamic>? getPrice(String symbol) {
    if (_priceService != null) {
      final quote = _priceService!.getQuote(symbol);
      if (quote != null) {
        return quote.toJson()..['symbol'] = symbol;
      }
    }
    return _internalLivePrices[symbol] ??
        _internalLivePrices[symbol.toUpperCase()];
  }

  // Restored Getters
  AvailableIndices? get availableIndices => _availableIndices;
  StockIndicesMarketData? get currentIndexData => _currentIndexData;

  /// Indian indices only (backward-compatible name used across the dashboard).
  List<StockIndicesMarketData> get allIndicesData => _allIndicesData;
  List<StockIndicesMarketData> get globalIndicesData => _globalIndicesData;
  IndicesRegion get indicesRegion => _indicesRegion;

  /// Indices shown in All Indices panel for the active region toggle.
  List<StockIndicesMarketData> get indicesForActiveRegion =>
      _indicesRegion == IndicesRegion.global
          ? _globalIndicesData
          : _allIndicesData;

  /// Union used by Compare Indices (mixed Indian + Global selection).
  List<StockIndicesMarketData> get indicesForCompare {
    final bySymbol = <String, StockIndicesMarketData>{};
    for (final i in _allIndicesData) {
      bySymbol[i.indexSymbol] = i;
    }
    for (final i in _globalIndicesData) {
      bySymbol[i.indexSymbol] = i;
    }
    return bySymbol.values.toList();
  }

  bool isGlobalSymbol(String symbol) {
    if (_globalIndicesData.any((e) => e.indexSymbol == symbol)) return true;
    return _availableIndices?.globalIndices.contains(symbol) ?? false;
  }

  void setIndicesRegion(IndicesRegion region) {
    if (_indicesRegion == region) return;
    _indicesRegion = region;
    notifyListeners();
    if (region == IndicesRegion.global && _globalIndicesData.isEmpty) {
      unawaited(loadGlobalIndicesData());
    }
  }

  // Cache for specific index constituents (used by Heatmap/Explorers)
  Map<String, List<StockData>> _indexConstituents = {};
  Map<String, List<StockData>> get indexConstituents => _indexConstituents;

  // Cache for Heatmap Data (Timeframe aware)
  Map<String, List<Map<String, dynamic>>> _heatmapData = {};
  Map<String, List<Map<String, dynamic>>> get heatmapData => _heatmapData;

  // Historical Performance Data (10Y view)
  HistoricalPerformanceResponse? _historicalPerformance;
  HistoricalPerformanceResponse? get historicalPerformance =>
      _historicalPerformance;

  // Seasonality Data
  SeasonalityResponse? _seasonality;
  SeasonalityResponse? get seasonality => _seasonality;

  String? get selectedIndex => _selectedIndex;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get forceRefresh => _forceRefresh;
  bool get indexSymbol => _indexSymbol;

  // New Heatmap Values (Symbol -> Change%)
  Map<String, double>? _heatmapValues;
  Map<String, double>? get heatmapValues => _heatmapValues;

  // Indices timeframe selection (1D uses live day change; others use historical base prices)
  String _selectedIndicesTimeframe = '1D';
  Map<String, double> _timeframeBasePrices = {};
  bool _isLoadingBasePrices = false;
  int _indicesRequestGeneration = 0;

  /// Close-price series for pinned index sparklines (from [ensureIndexSparklines]).
  Map<String, List<double>> _indexSparklines = {};
  bool _isLoadingSparklines = false;
  String? _sparklineRange;

  String get selectedIndicesTimeframe => _selectedIndicesTimeframe;
  Map<String, double> get timeframeBasePrices => _timeframeBasePrices;
  bool get isLoadingBasePrices => _isLoadingBasePrices;
  Map<String, List<double>> get indexSparklines => _indexSparklines;
  bool get isLoadingSparklines => _isLoadingSparklines;

  Future<void> setIndicesTimeframe(String timeframe) async {
    if (_selectedIndicesTimeframe == timeframe) return;

    _selectedIndicesTimeframe = timeframe;
    final requestGeneration = ++_indicesRequestGeneration;
    notifyListeners();

    if (timeframe == '1D') {
      _timeframeBasePrices.clear();
      _isLoadingBasePrices = false;
      notifyListeners();
      // Reload without timeframe to get standard 1D data
      await loadAllIndicesData(requestGeneration: requestGeneration);
      return;
    }

    _isLoadingBasePrices = true;
    notifyListeners();

    try {
      // Data format handles the timeframe changes on the backend now.
      // So we just need to re-fetch the indices batch.
      await loadAllIndicesData(requestGeneration: requestGeneration);
    } catch (e) {
      CommonLogger.error(
        "Error fetching timeframe data for $timeframe",
        tag: "MarketProvider.setIndicesTimeframe",
        error: e,
      );
    } finally {
      if (requestGeneration == _indicesRequestGeneration) {
        _isLoadingBasePrices = false;
        notifyListeners();
      }
    }
  }

  /// [SIP Optimization] Allows the preloading scheduler and on-demand fetches to register
  /// historical reference prices directly into the provider cache, synchronizing states.
  void updateTimeframeBasePrices(
      String timeframe, Map<String, double> basePrices) {
    if (timeframe == '1D') return;
    _timeframeBasePrices.addAll(basePrices);
    notifyListeners();
  }

  /// Loads mini close-price series for index sparkline cards.
  /// Skips symbols already cached for [range]. Safe to call repeatedly.
  /// Concurrent calls while a fetch is in flight are ignored (no rebuild storm).
  Future<void> ensureIndexSparklines(
    List<String> symbols, {
    String range = '1W',
  }) async {
    if (_isLoadingSparklines) return;

    final unique = symbols
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (unique.isEmpty) return;

    if (_sparklineRange != null && _sparklineRange != range) {
      _indexSparklines.clear();
    }
    _sparklineRange = range;

    final missing =
        unique.where((s) => (_indexSparklines[s]?.length ?? 0) < 2).toList();
    if (missing.isEmpty) return;

    _isLoadingSparklines = true;
    // Safe to notify: callers must not invoke this from build, and the
    // in-flight guard above blocks re-entry (preserves web sparkline shimmer).
    notifyListeners();

    try {
      final fetcher = debugHistoryBatchFetcher ?? _apiService.fetchHistoryBatch;
      final history = await fetcher(missing, range);
      history.forEach((sym, points) {
        final closes = extractSparklineCloses(points);
        if (closes.length >= 2) {
          _indexSparklines[sym] = closes;
        }
      });
    } catch (e) {
      CommonLogger.error(
        'Error fetching index sparklines',
        tag: 'MarketProvider.ensureIndexSparklines',
        error: e,
      );
    } finally {
      _isLoadingSparklines = false;
      notifyListeners();
    }
  }

  /// Maps history data-points to a sparkline close series (testable helper).
  static List<double> extractSparklineCloses(
      List<Map<String, dynamic>> points) {
    final closes = <double>[];
    for (final point in points) {
      final raw = point['close'] ??
          point['price'] ??
          point['lastPrice'] ??
          point['value'];
      if (raw is num && raw > 0) {
        closes.add(raw.toDouble());
      }
    }
    return closes;
  }

  void toggleForceRefresh(bool value) {
    _forceRefresh = value;
    notifyListeners();
  }

  void toggleIndexSymbol(bool value) {
    if (_indexSymbol == value) return;
    _indexSymbol = value;
    notifyListeners();
    // Auto-reload data when toggle changes (subscriptions stay — add-only)
    if (_selectedIndex == "All Indices") {
      loadAllIndicesData();
    }
  }

  void updateLivePriceBatch(Map<String, dynamic> quotes) {
    // No-op if using PriceService as it handles its own updates
    if (_priceService != null) return;

    // Fallback for legacy
    if (quotes.isEmpty) return;

    // 1. Summary Log (Once per batch)
    final count = quotes.length;
    final firstKey = quotes.keys.first;
    final firstVal = quotes[firstKey] as Map;

    String logMsg =
        "Received update for optimized batch: $count symbols. Sample: $firstKey -> Price: ${firstVal['lastPrice']}";
    if (count > 1) {
      logMsg += " and ${count - 1} others.";
    }
    CommonLogger.info(logMsg, tag: "MarketUI");

    // 2. Process all
    quotes.forEach((symbol, data) {
      if (data is Map<String, dynamic>) {
        _processSingleUpdate(symbol, data);
      }
    });
  }

  void updateLivePrice(Map<String, dynamic> data) {
    if (_priceService != null) return;
    if (data.containsKey('symbol')) {
      _processSingleUpdate(data['symbol'], data);
    }
  }

  void _processSingleUpdate(String rawSymbol, Map<String, dynamic> data) {
    // 1. Store with raw key
    _internalLivePrices[rawSymbol] = data;
    _internalLivePrices[rawSymbol.toUpperCase()] = data;

    // 2. Store with base key
    if (rawSymbol.contains(':')) {
      final baseSymbol = rawSymbol.split(':').last.toUpperCase();
      _internalLivePrices[baseSymbol] = data;
    }
    if (rawSymbol.contains('|')) {
      final baseSymbol = rawSymbol.split('|').last.toUpperCase();
      _internalLivePrices[baseSymbol] = data;
    }

    // 3. Update allIndicesData
    String updateSymbolBase =
        rawSymbol.contains('|') ? rawSymbol.split('|').last : rawSymbol;

    for (int i = 0; i < _allIndicesData.length; i++) {
      if (_allIndicesData[i].indexSymbol.toUpperCase() ==
          updateSymbolBase.toUpperCase()) {
        final current = _allIndicesData[i];
        final double? newLtp = data['lastPrice']?.toDouble();
        final double? newPChange = data['changePercent']?.toDouble();

        if (newLtp != null) {
          _allIndicesData[i] = current.copyWith(
              lastPrice: newLtp, pChange: newPChange ?? current.pChange);
          _notifyThrottled();
        }
        break;
      }
    }

    // Emit event
    _livePriceController.add(data);
  }

  void _notifyThrottled() {
    final now = DateTime.now();
    if (_lastNotify != null && now.difference(_lastNotify!) < _notifyThrottle) {
      return;
    }
    _lastNotify = now;
    notifyListeners();
  }

  void _syncWithPriceService() {
    if (_priceService == null) {
      CommonLogger.warning("Skipping sync - PriceService is null",
          tag: "MarketProvider._syncWithPriceService");
      return;
    }

    if (_allIndicesData.isEmpty) {
      CommonLogger.warning("Skipping sync - No indices loaded",
          tag: "MarketProvider._syncWithPriceService");
      return;
    }

    final symbols = _allIndicesData.map((e) => e.indexSymbol).toList();
    final quotes = _priceService!.getQuotes(symbols);

    CommonLogger.info(
        "Attempting to sync prices for ${symbols.length} symbols. Found ${quotes.length} in PriceService cache.",
        tag: "MarketProvider._syncWithPriceService");

    if (quotes.isNotEmpty) {
      quotes.forEach((symbol, quote) {
        final data = quote.toJson();
        data['symbol'] = symbol;
        _processSingleUpdate(symbol, data);
      });
    }
  }

  @override
  void dispose() {
    _priceUpdateSub?.cancel();
    _livePriceController.close();
    super.dispose();
  }

  Future<void> loadIndices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.fetchAvailableIndices(),
        _apiService.fetchAvailableGlobalIndices().catchError((e) {
          CommonLogger.warning(
            "Global available indices unavailable: $e",
            tag: "MarketProvider.loadIndices",
          );
          return <String>[];
        }),
      ]);
      final indian = results[0] as AvailableIndices;
      final global = results[1] as List<String>;
      _availableIndices = indian.copyWith(globalIndices: global);
      CommonLogger.info(
        "Fetched available indices: ${indian.broad.length} broad, ${indian.sectoral.length} sectoral, ${global.length} global",
        tag: "MarketProvider.loadIndices",
      );
      if (_availableIndices?.broad.isNotEmpty ?? false) {
        // Auto-select "All Indices" by default to show overview
        selectIndex("All Indices");
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectIndex(String indexSymbol) async {
    final previous = _selectedIndex;
    if (previous == indexSymbol) {
      if (indexSymbol == "All Indices" &&
          _allIndicesData.isNotEmpty &&
          !_forceRefresh) {
        return;
      }
      if (indexSymbol == "Dashboard" &&
          _allIndicesData.isNotEmpty &&
          !_forceRefresh) {
        return;
      }
      if (!["All Indices", "Dashboard", "Streamer"].contains(indexSymbol) &&
          _currentIndexData != null &&
          previous == indexSymbol &&
          !_forceRefresh) {
        return;
      }
    }

    CommonLogger.info("Selecting: $indexSymbol",
        tag: "MarketProvider.selectIndex");

    _selectedIndex = indexSymbol;
    if (_selectedIndex == "All Indices") {
      await loadAllIndicesData();
    } else if (_selectedIndex == "Dashboard") {
      // Dashboard needs all indices data just like "All Indices"
      CommonLogger.debug("Loading Dashboard data",
          tag: "MarketProvider.selectIndex");
      await loadAllIndicesData();
    } else if (isNavigationOnlySelection(_selectedIndex)) {
      CommonLogger.debug(
          "Selected view: $_selectedIndex (no data fetch required)",
          tag: "MarketProvider.selectIndex");
      // Do nothing, just update selection
      notifyListeners();
    } else {
      await refreshIndexData();
    }
  }

  Future<void> refreshIndexData() async {
    if (_selectedIndex == null ||
        _selectedIndex == "All Indices" ||
        _selectedIndex == "Streamer" ||
        isNavigationOnlySelection(_selectedIndex)) {
      CommonLogger.debug("Skip refresh for $_selectedIndex",
          tag: "MarketProvider.refreshIndexData");
      return;
    }

    CommonLogger.info("Refreshing data for $_selectedIndex",
        tag: "MarketProvider.refreshIndexData");
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentIndexData = await _apiService.fetchIndexData(_selectedIndex!,
          forceRefresh: _forceRefresh);
      CommonLogger.debug(
          "Data refreshed for $_selectedIndex. Constituents: ${_currentIndexData?.stocks.length ?? 0}",
          tag: "MarketProvider.refreshIndexData");
      if (_selectedIndex != null) {
        await _ensurePriceSubscription([_selectedIndex!]);
        _syncWithPriceService();
      }
    } catch (e) {
      CommonLogger.error("Error refreshing $_selectedIndex",
          tag: "MarketProvider.refreshIndexData", error: e);

      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllIndicesData({int? requestGeneration}) async {
    final currentGeneration = requestGeneration ?? ++_indicesRequestGeneration;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // STEP 1: Fetch available indices first if not already loaded
      if (_availableIndices == null) {
        final indian = await _apiService.fetchAvailableIndices();
        final global =
            await _apiService.fetchAvailableGlobalIndices().catchError((e) {
          CommonLogger.warning(
            "Global available indices unavailable: $e",
            tag: "MarketProvider.loadAllIndicesData",
          );
          return <String>[];
        });
        _availableIndices = indian.copyWith(globalIndices: global);
        CommonLogger.info("Fetched available indices",
            tag: "MarketProvider.loadAllIndicesData");
      } else if (_availableIndices!.globalIndices.isEmpty) {
        final global = await _apiService
            .fetchAvailableGlobalIndices()
            .catchError((_) => <String>[]);
        _availableIndices = _availableIndices!.copyWith(globalIndices: global);
      }

      // STEP 2: Indian symbols only for _allIndicesData (NSE movers / pinned stay Indian-first)
      List<String> indianSymbols = _availableIndices?.indianSymbols ?? [];

      if (indianSymbols.isEmpty) {
        _error = "No indices available";
        CommonLogger.warning("No indices available",
            tag: "MarketProvider.loadAllIndicesData");

        return;
      }

      CommonLogger.info("Loading ${indianSymbols.length} Indian indices",
          tag: "MarketProvider.loadAllIndicesData");

      // STEP 3: Call batch endpoint with Indian symbols and the selected timeframe
      final loadedIndices = await _apiService.fetchIndicesBatch(indianSymbols,
          forceRefresh: _forceRefresh,
          timeframe: _selectedIndicesTimeframe == '1D'
              ? null
              : _selectedIndicesTimeframe);
      if (currentGeneration != _indicesRequestGeneration) return;
      _allIndicesData = loadedIndices;

      CommonLogger.info(
          "Successfully loaded ${_allIndicesData.length} Indian indices with timeframe $_selectedIndicesTimeframe",
          tag: "MarketProvider.loadAllIndicesData");

      // Warm once; it is not needed to render the Indian indices currently on screen.
      if (_globalIndicesData.isEmpty) {
        unawaited(loadGlobalIndicesData());
      }

      await _ensurePriceSubscription(
        _allIndicesData
            .take(_maxLiveStreamSymbols)
            .map((e) => e.indexSymbol)
            .toList(),
      );
      _syncWithPriceService();
    } catch (e) {
      CommonLogger.error("Error loading all indices",
          tag: "MarketProvider.loadAllIndicesData", error: e);
      if (currentGeneration == _indicesRequestGeneration) {
        _error = e.toString();
      }
    } finally {
      if (currentGeneration == _indicesRequestGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadGlobalIndicesData() async {
    try {
      if (_availableIndices == null ||
          _availableIndices!.globalIndices.isEmpty) {
        final global = await _apiService.fetchAvailableGlobalIndices();
        _availableIndices = (_availableIndices ?? AvailableIndices())
            .copyWith(globalIndices: global);
      }
      final symbols = _availableIndices?.globalIndices ?? [];
      if (symbols.isEmpty) {
        _globalIndicesData = [];
        notifyListeners();
        return;
      }
      CommonLogger.info(
        "Loading ${symbols.length} global indices",
        tag: "MarketProvider.loadGlobalIndicesData",
      );
      _globalIndicesData = await _apiService.fetchIndicesBatch(
        symbols,
        forceRefresh: _forceRefresh,
      );
      CommonLogger.info(
        "Successfully loaded ${_globalIndicesData.length} global indices",
        tag: "MarketProvider.loadGlobalIndicesData",
      );
      notifyListeners();
    } catch (e) {
      CommonLogger.error(
        "Error loading global indices",
        tag: "MarketProvider.loadGlobalIndicesData",
        error: e,
      );
      // Keep Indian flow healthy even if global fails.
    }
  }

  Future<void> refreshCookies() async {
    bool success = await _apiService.refreshCookies();
    if (success) {
      // Re-fetch current view data
      if (_selectedIndex == "All Indices") {
        await loadAllIndicesData();
      } else if (_selectedIndex != null) {
        await refreshIndexData();
      }
    } else {
      _error = "Failed to refresh cookies";
      notifyListeners();
    }
  }

  Future<void> fetchIndexConstituents(String indexSymbol) async {
    CommonLogger.info("Fetching constituents for: $indexSymbol",
        tag: "MarketProvider.fetchIndexConstituents");
    try {
      final data = await _apiService.fetchIndexData(indexSymbol,
          forceRefresh: _forceRefresh);
      if (data != null) {
        _indexConstituents[indexSymbol] = data.stocks;
        notifyListeners();
      }
    } catch (e) {
      CommonLogger.error("Error fetching constituents for $indexSymbol",
          tag: "MarketProvider.fetchIndexConstituents", error: e);
      // Don't set global error to avoid disrupting other views
    }
  }

  Future<void> fetchHeatmapData(String indexSymbol, String timeFrame) async {
    final key = "$indexSymbol:$timeFrame";
    CommonLogger.info("Fetching heatmap data to key: $key",
        tag: "MarketProvider.fetchHeatmapData");

    try {
      // Use new dedicated endpoint for full index performance
      final result = await _apiService.fetchIndexPerformance(
        indexSymbol: indexSymbol,
        timeFrame: timeFrame,
      );

      _heatmapData[key] = result;
      notifyListeners();
    } catch (e) {
      CommonLogger.error("Error fetching heatmap data",
          tag: "MarketProvider.fetchHeatmapData", error: e);
    }
  }

  Future<void> loadHistoricalPerformance(String symbol) async {
    CommonLogger.info("Loading historical performance for $symbol",
        tag: "MarketProvider.loadHistoricalPerformance");
    _isLoading = true;
    // Don't clear previous data immediately to avoid flicker, or maybe clear if symbol changed
    // For now, let's keep it simple
    notifyListeners();

    try {
      // Hardcoded 10 years as per requirement
      _historicalPerformance =
          await _apiService.fetchHistoricalPerformance(symbol, years: 10);
    } catch (e) {
      CommonLogger.error("Error loading historical performance",
          tag: "MarketProvider.loadHistoricalPerformance", error: e);
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int _heatmapLoadId = 0;

  /// Dashboard heatmap: prefer full index constituents (NIFTY 500 ≈ 500 tiles),
  /// enrich % from analysis heatmap when present, else stock batch pChange.
  Future<List<MapEntry<String, double>>> loadDashboardIndexHeatmap(
    String symbol,
    String timeframe,
  ) async {
    final trimmed = symbol.trim();
    final heatmapFuture = loadHeatmap(trimmed, timeframe);
    final indexFuture = () async {
      try {
        return await _apiService.fetchIndexData(trimmed);
      } catch (e) {
        CommonLogger.warning(
          'Index constituents unavailable for $trimmed: $e',
          tag: 'MarketProvider.loadDashboardIndexHeatmap',
        );
        return null;
      }
    }();

    final heatmap = await heatmapFuture;
    final indexData = await indexFuture;
    var heatmapMap = heatmap;
    // If analysis heatmap is mostly zeros but we have constituents, force-refresh once.
    if (indexData != null &&
        indexData.stocks.length >= 20 &&
        heatmapMap.isNotEmpty &&
        _isMostlyZeroHeatmap(heatmapMap)) {
      heatmapMap = await _apiService.fetchHeatmap(
        trimmed,
        timeframe: timeframe,
        forceRefresh: true,
      );
    }
    return mergeDashboardHeatmapEntries(
      heatmap: heatmapMap,
      stocks: indexData?.stocks ?? const [],
    );
  }

  bool _isMostlyZeroHeatmap(Map<String, double> values) {
    if (values.isEmpty) return true;
    final zeros = values.values.where((v) => v.abs() < 1e-9).length;
    return zeros * 10 >= values.length * 7;
  }

  /// Loads heatmap for [symbol]. Always returns the fetched map for the caller
  /// (dashboard must not rely on shared [heatmapValues], which Analysis can race).
  Future<Map<String, double>> loadHeatmap(
      String symbol, String timeframe) async {
    final loadId = ++_heatmapLoadId;
    CommonLogger.info("Loading heatmap for $symbol ($timeframe)",
        tag: "MarketProvider.loadHeatmap");
    try {
      var values = await _apiService.fetchHeatmap(symbol, timeframe: timeframe);
      // Stale/bad INDICES 1D Redis cache often returns almost all 0.0 — recompute once.
      if (_isDegenerateIndicesHeatmap(symbol, timeframe, values)) {
        CommonLogger.warning(
          "Degenerate INDICES heatmap cache detected; retrying with forceRefresh",
          tag: "MarketProvider.loadHeatmap",
        );
        values = await _apiService.fetchHeatmap(
          symbol,
          timeframe: timeframe,
          forceRefresh: true,
        );
      }
      // Only publish to shared state if this is still the latest request.
      if (loadId == _heatmapLoadId) {
        _heatmapValues = values;
        notifyListeners();
      }
      return values;
    } catch (e) {
      CommonLogger.error("Error loading heatmap",
          tag: "MarketProvider.loadHeatmap", error: e);
      if (loadId == _heatmapLoadId) {
        _heatmapValues = {};
        notifyListeners();
      }
      return {};
    }
  }

  bool _isDegenerateIndicesHeatmap(
    String symbol,
    String timeframe,
    Map<String, double> values,
  ) {
    if (symbol.toUpperCase() != 'INDICES') return false;
    if (timeframe.toUpperCase() != '1D') return false;
    if (values.length < 5) return false;
    final zeros = values.values.where((v) => v.abs() < 1e-9).length;
    return zeros * 10 >= values.length * 7;
  }

  Future<void> loadSeasonality(String symbol) async {
    CommonLogger.info("Loading seasonality for $symbol",
        tag: "MarketProvider.loadSeasonality");
    try {
      _seasonality = await _apiService.fetchSeasonality(symbol);
      notifyListeners();
    } catch (e) {
      CommonLogger.error("Error loading seasonality",
          tag: "MarketProvider.loadSeasonality", error: e);
    }
  }
}

/// Merge analysis heatmap % with index constituents.
/// When constituents are many (e.g. NIFTY 500), they drive the tile list.
List<MapEntry<String, double>> mergeDashboardHeatmapEntries({
  required Map<String, double> heatmap,
  required List<StockData> stocks,
}) {
  if (stocks.length >= 20) {
    final entries = <MapEntry<String, double>>[];
    for (final stock in stocks) {
      final symbol = stock.symbol.trim();
      if (symbol.isEmpty) continue;
      final fromHeat = heatmap[symbol];
      final pct = (fromHeat != null && fromHeat.abs() > 1e-9)
          ? fromHeat
          : stock.pChange;
      entries.add(MapEntry(symbol, pct));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  if (heatmap.isNotEmpty) {
    final entries = heatmap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  final entries = <MapEntry<String, double>>[];
  for (final stock in stocks) {
    final symbol = stock.symbol.trim();
    if (symbol.isEmpty) continue;
    entries.add(MapEntry(symbol, stock.pChange));
  }
  entries.sort((a, b) => b.value.compareTo(a.value));
  return entries;
}

/// Paging window for dashboard heatmap grids (unit-tested).
({int pageCount, int start, int end}) dashboardHeatmapPageWindow({
  required int total,
  required int page,
  required int pageSize,
}) {
  if (total <= 0 || pageSize <= 0) {
    return (pageCount: 1, start: 0, end: 0);
  }
  final pageCount = (total + pageSize - 1) ~/ pageSize;
  final safePage = page.clamp(0, pageCount - 1);
  final start = safePage * pageSize;
  final end = (start + pageSize).clamp(0, total);
  return (pageCount: pageCount, start: start, end: end);
}
