import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_market_sdk/market/api.dart';
import 'package:am_design_system/am_design_system.dart';
import 'package:am_market_ui/core/services/market_data_sdk_service.dart';
import 'package:am_auth_ui/core/services/secure_storage_service.dart';
import 'package:get_it/get_it.dart';

/// In-session recently viewed stocks (max 5). 
/// Reset when browser refreshes or new session begins.
final recentlyViewedStocksProvider =
    NotifierProvider<RecentlyViewedStocksNotifier, List<String>>(
  RecentlyViewedStocksNotifier.new,
);

class RecentlyViewedStocksNotifier extends Notifier<List<String>> {
  static const int maxRecent = 5;

  @override
  List<String> build() => const [];

  void recordView(String symbol) {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return;
    final updated = List<String>.from(state);
    updated.remove(sym);
    updated.insert(0, sym);
    if (updated.length > maxRecent) {
      state = updated.sublist(0, maxRecent);
    } else {
      state = updated;
    }
  }

  void removeView(String symbol) {
    final sym = symbol.trim().toUpperCase();
    if (sym.isEmpty) return;
    final updated = List<String>.from(state);
    updated.remove(sym);
    state = updated;
  }

  void clear() {
    state = const [];
  }
}

/// Active selected exchange provider ('NSE' vs 'BSE')
final selectedExchangeProvider =
    NotifierProvider<SelectedExchangeNotifier, String>(
  SelectedExchangeNotifier.new,
);

class SelectedExchangeNotifier extends Notifier<String> {
  @override
  String build() => 'NSE';

  void setExchange(String exchange) {
    state = exchange;
  }
}

class EquityFundamentalQuery {
  final String symbol;
  final String exchange;

  const EquityFundamentalQuery({
    required this.symbol,
    this.exchange = 'NSE',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquityFundamentalQuery &&
          runtimeType == other.runtimeType &&
          symbol.toUpperCase() == other.symbol.toUpperCase() &&
          exchange.toUpperCase() == other.exchange.toUpperCase();

  @override
  int get hashCode => symbol.toUpperCase().hashCode ^ exchange.toUpperCase().hashCode;
}

class EquityChartQuery {
  final String symbol;
  final String timeframe;
  final String exchange;

  const EquityChartQuery({
    required this.symbol,
    required this.timeframe,
    this.exchange = 'NSE',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EquityChartQuery &&
          runtimeType == other.runtimeType &&
          symbol.toUpperCase() == other.symbol.toUpperCase() &&
          timeframe.toUpperCase() == other.timeframe.toUpperCase() &&
          exchange.toUpperCase() == other.exchange.toUpperCase();

  @override
  int get hashCode =>
      symbol.toUpperCase().hashCode ^
      timeframe.toUpperCase().hashCode ^
      exchange.toUpperCase().hashCode;
}

final equityStockChartDataProvider =
    FutureProvider.family<MultiSeriesChartData, EquityChartQuery>((ref, query) async {
  final sdkService = MarketDataSdkService();
  try {
    if (GetIt.I.isRegistered<SecureStorageService>()) {
      final token = await GetIt.I<SecureStorageService>().getAccessToken();
      if (token != null && token.isNotEmpty) {
        sdkService.setAuthentication(token);
      }
    }
  } catch (_) {}

  try {
    final chartSymbol = (query.exchange.toUpperCase() == 'BSE' && !query.symbol.contains(':'))
        ? 'BSE:${query.symbol}'
        : query.symbol;
    final response = await sdkService.analyticsApi.getHistoricalCharts(
      chartSymbol,
      range: query.timeframe,
      isIndexSymbol: false,
    );

    List<OHLCVTPoint> dataPoints = [];

    if (response != null && response.data.isNotEmpty) {
      final symKey = response.data.keys.firstWhere(
        (k) => k.toUpperCase() == chartSymbol.toUpperCase() || k.toUpperCase() == query.symbol.toUpperCase(),
        orElse: () => response.data.keys.first,
      );
      final historical = response.data[symKey];
      if (historical != null && historical.dataPoints.isNotEmpty) {
        dataPoints = historical.dataPoints;
      }
    }

    // 1W Fallback: If 1W (hourly) returned 0 points, fetch 1M (daily) and slice the last 7 sessions
    if (dataPoints.isEmpty && query.timeframe.toUpperCase() == '1W') {
      try {
        final mResponse = await sdkService.analyticsApi.getHistoricalCharts(
          chartSymbol,
          range: '1M',
          isIndexSymbol: false,
        );
        if (mResponse != null && mResponse.data.isNotEmpty) {
          final symKey = mResponse.data.keys.firstWhere(
            (k) => k.toUpperCase() == chartSymbol.toUpperCase() || k.toUpperCase() == query.symbol.toUpperCase(),
            orElse: () => mResponse.data.keys.first,
          );
          final mHist = mResponse.data[symKey];
          if (mHist != null && mHist.dataPoints.isNotEmpty) {
            dataPoints = mHist.dataPoints.length > 7
                ? mHist.dataPoints.sublist(mHist.dataPoints.length - 7)
                : mHist.dataPoints;
          }
        }
      } catch (_) {}
    }

    // 1D Fallback: If 1D returned 0 points (e.g. post-market), synthesize session line from Live LTP
    if (dataPoints.isEmpty && query.timeframe.toUpperCase() == '1D') {
      try {
        final ltpRes = await sdkService.marketDataApi.getLiveLTP(
          chartSymbol,
          isIndexSymbol: false,
        );
        if (ltpRes != null && ltpRes.containsKey('data') && ltpRes['data'] is Map) {
          final dataMap = ltpRes['data'] as Map;
          final symKey = dataMap.keys.firstWhere(
            (k) => k.toString().toUpperCase() == chartSymbol.toUpperCase() || k.toString().toUpperCase() == query.symbol.toUpperCase(),
            orElse: () => null,
          );
          if (symKey != null) {
            final item = dataMap[symKey] as Map;
            final lp = (item['lastPrice'] as num?)?.toDouble();
            final prev = (item['previousClose'] as num?)?.toDouble() ?? lp;
            if (lp != null && lp > 0) {
              final now = DateTime.now();
              final tOpen = DateTime(now.year, now.month, now.day, 9, 15);
              final tClose = DateTime(now.year, now.month, now.day, 15, 30);

              final rows = [
                {
                  'time': tOpen.toIso8601String(),
                  'close': prev,
                  'open': prev,
                  'high': prev,
                  'low': prev,
                  'volume': 0,
                },
                {
                  'time': tClose.toIso8601String(),
                  'close': lp,
                  'open': prev,
                  'high': max(lp, prev!),
                  'low': min(lp, prev),
                  'volume': 0,
                },
              ];
              return MultiSeriesChartData.fromRows(
                rows,
                label: query.symbol.toUpperCase(),
                isIntraday: true,
              );
            }
          }
        }
      } catch (_) {}
    }

    if (dataPoints.isEmpty) {
      return const MultiSeriesChartData(series: {});
    }

    final isIntraday = query.timeframe.toUpperCase() == '1D';
    final rows = <Map<String, dynamic>>[];
    for (final dp in dataPoints) {
      if (dp.close != null && dp.time != null) {
        rows.add({
          'time': dp.time!.toIso8601String(),
          'close': dp.close,
          'open': dp.open,
          'high': dp.high,
          'low': dp.low,
          'volume': dp.volume,
        });
      }
    }

    return MultiSeriesChartData.fromRows(
      rows,
      label: query.symbol.toUpperCase(),
      isIntraday: isIntraday,
    );
  } catch (e) {
    throw Exception('Failed to load chart data for ${query.symbol} (${query.timeframe}): $e');
  }
});

final fundamentalProfileProvider =
    FutureProvider.family<FundamentalRatiosResponse?, EquityFundamentalQuery>((ref, query) async {
  final sdkService = MarketDataSdkService();
  try {
    if (GetIt.I.isRegistered<SecureStorageService>()) {
      final token = await GetIt.I<SecureStorageService>().getAccessToken();
      if (token != null && token.isNotEmpty) {
        sdkService.setAuthentication(token);
      }
    }
  } catch (_) {}
  try {
    return await sdkService.fundamentalApi.getProfile(query.symbol, exchange: query.exchange);
  } catch (e) {
    throw Exception('Failed to load profile for ${query.symbol}: $e');
  }
});

final fundamentalRatiosProvider =
    FutureProvider.family<FundamentalRatiosResponse?, EquityFundamentalQuery>((ref, query) async {
  final sdkService = MarketDataSdkService();
  try {
    if (GetIt.I.isRegistered<SecureStorageService>()) {
      final token = await GetIt.I<SecureStorageService>().getAccessToken();
      if (token != null && token.isNotEmpty) {
        sdkService.setAuthentication(token);
      }
    }
  } catch (_) {}
  try {
    return await sdkService.fundamentalApi.getRatios(query.symbol, exchange: query.exchange);
  } catch (e) {
    throw Exception('Failed to load ratios for ${query.symbol}: $e');
  }
});

final fundamentalUnifiedProvider =
    FutureProvider.family<FundamentalRatiosResponse?, EquityFundamentalQuery>((ref, query) async {
  final sdkService = MarketDataSdkService();
  try {
    if (GetIt.I.isRegistered<SecureStorageService>()) {
      final token = await GetIt.I<SecureStorageService>().getAccessToken();
      if (token != null && token.isNotEmpty) {
        sdkService.setAuthentication(token);
      }
    }
  } catch (_) {}
  try {
    return await sdkService.fundamentalApi.getFundamentals(query.symbol, exchange: query.exchange);
  } catch (e) {
    throw Exception('Failed to load fundamentals for ${query.symbol}: $e');
  }
});

final fundamentalFinancialsProvider =
    FutureProvider.family<FundamentalRatiosResponse?, String>((ref, symbol) async {
  final sdkService = MarketDataSdkService();
  try {
    if (GetIt.I.isRegistered<SecureStorageService>()) {
      final token = await GetIt.I<SecureStorageService>().getAccessToken();
      if (token != null && token.isNotEmpty) {
        sdkService.setAuthentication(token);
      }
    }
  } catch (_) {}
  try {
    return await sdkService.fundamentalApi.getFinancials(symbol);
  } catch (e) {
    throw Exception('Failed to load financials for $symbol: $e');
  }
});

final fundamentalShareholdingProvider =
    FutureProvider.family<List<dynamic>?, String>((ref, symbol) async {
  final sdkService = MarketDataSdkService();
  try {
    if (GetIt.I.isRegistered<SecureStorageService>()) {
      final token = await GetIt.I<SecureStorageService>().getAccessToken();
      if (token != null && token.isNotEmpty) {
        sdkService.setAuthentication(token);
      }
    }
  } catch (_) {}
  try {
    return await sdkService.fundamentalApi.getShareholding(symbol);
  } catch (e) {
    throw Exception('Failed to load shareholding for $symbol: $e');
  }
});

final fundamentalPeersProvider =
    FutureProvider.family<List<CompetitorPeer>?, EquityFundamentalQuery>((ref, query) async {
  final sdkService = MarketDataSdkService();
  try {
    if (GetIt.I.isRegistered<SecureStorageService>()) {
      final token = await GetIt.I<SecureStorageService>().getAccessToken();
      if (token != null && token.isNotEmpty) {
        sdkService.setAuthentication(token);
      }
    }
  } catch (_) {}

  try {
    final peers = await sdkService.fundamentalApi.getPeers(query.symbol, exchange: query.exchange);

    if (peers != null && peers.isNotEmpty) {
      final symbolsToFetch = <String>{};
      symbolsToFetch.add(query.symbol); // main symbol
      for (final p in peers) {
        if (p.symbol != null && p.symbol!.isNotEmpty) symbolsToFetch.add(p.symbol!);
      }

      if (symbolsToFetch.isNotEmpty) {
        try {
          final prefix = query.exchange.toUpperCase() == 'BSE' ? 'BSE:' : '';
          final qualifiedSymbols = symbolsToFetch.map((s) => s.contains(':') ? s : prefix + s).join(',');
          // Fetch accurate live LTP and day change percentages from /v1/market-data/live-ltp
          final ltpRes = await sdkService.marketDataApi.getLiveLTP(
            qualifiedSymbols,
            isIndexSymbol: false,
          );

          if (ltpRes != null && ltpRes.containsKey('data') && ltpRes['data'] is Map) {
            final dataMap = ltpRes['data'] as Map;

            for (final p in peers) {
              final sym = p.symbol?.toUpperCase();
              final qualSym = (prefix + (sym ?? '')).toUpperCase();
              final itemKey = dataMap.containsKey(qualSym) ? qualSym : (dataMap.containsKey(sym) ? sym : null);
              if (itemKey != null) {
                final item = dataMap[itemKey] is Map ? dataMap[itemKey] as Map : null;
                if (item != null) {
                  if (item['lastPrice'] != null) {
                    final lp = (item['lastPrice'] as num).toDouble();
                    if (lp > 0) p.currentPrice = lp;
                  }
                  if (item['change'] != null) {
                    p.dayChange = (item['change'] as num).toDouble();
                  }
                  if (item['changePercent'] != null) {
                    p.dayChangePercent = (item['changePercent'] as num).toDouble();
                  }
                }
              }
            }
          }
        } catch (_) {
          // Ignore live price enrichment failure gracefully
        }
      }
    }
    return peers;
  } catch (e) {
    throw Exception('Failed to load peers for ${query.symbol}: $e');
  }
});
