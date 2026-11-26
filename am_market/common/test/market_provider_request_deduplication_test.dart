import 'dart:async';

import 'package:am_auth_ui/core/services/secure_storage_service.dart';
import 'package:am_market_common/models/available_indices.dart';
import 'package:am_market_common/models/market_data.dart';
import 'package:am_market_common/providers/market_provider.dart';
import 'package:am_market_common/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

class _CountingApiService extends ApiService {
  _CountingApiService(
      {Completer<void>? availableGate, Completer<void>? heatmapGate})
      : _availableGate = availableGate,
        _heatmapGate = heatmapGate;

  final Completer<void>? _availableGate;
  final Completer<void>? _heatmapGate;
  int indianAvailableCalls = 0;
  int globalAvailableCalls = 0;
  int heatmapCalls = 0;

  @override
  Future<AvailableIndices> fetchAvailableIndices() async {
    indianAvailableCalls++;
    await _availableGate?.future;
    return AvailableIndices(broadMarketIndices: const ['NIFTY 50']);
  }

  @override
  Future<List<String>> fetchAvailableGlobalIndices() async {
    globalAvailableCalls++;
    await _availableGate?.future;
    return const ['SPX'];
  }

  @override
  Future<List<StockIndicesMarketData>> fetchIndicesBatch(
    List<String> symbols, {
    bool forceRefresh = false,
    String? timeframe,
  }) async =>
      const [];

  @override
  Future<StockIndicesMarketData> fetchIndexData(
    String indexSymbol, {
    bool forceRefresh = false,
  }) =>
      Future<StockIndicesMarketData>.error(StateError('not needed by test'));

  @override
  Future<Map<String, double>> fetchHeatmap(
    String symbol, {
    String timeframe = '1D',
    bool forceRefresh = false,
  }) async {
    heatmapCalls++;
    await _heatmapGate?.future;
    return const {'TCS': 1.25};
  }
}

void main() {
  setUpAll(() {
    if (!GetIt.I.isRegistered<SecureStorageService>()) {
      GetIt.I.registerSingleton<SecureStorageService>(SecureStorageService());
    }
  });

  test('shares concurrent available-index requests', () async {
    final gate = Completer<void>();
    final api = _CountingApiService(availableGate: gate);
    final provider = MarketProvider(apiService: api);

    final first = provider.loadIndices();
    final second = provider.loadIndices();

    expect(api.indianAvailableCalls, 1);
    expect(api.globalAvailableCalls, 1);

    gate.complete();
    await Future.wait([first, second]);
  });

  test('shares concurrent dashboard heatmap requests for the same key',
      () async {
    final gate = Completer<void>();
    final api = _CountingApiService(heatmapGate: gate);
    final provider = MarketProvider(apiService: api);

    final first = provider.loadDashboardIndexHeatmap('NIFTY 50', '1D');
    final second = provider.loadDashboardIndexHeatmap(' nifty 50 ', '1d');

    expect(api.heatmapCalls, 1);

    gate.complete();
    await Future.wait([first, second]);
  });
}
