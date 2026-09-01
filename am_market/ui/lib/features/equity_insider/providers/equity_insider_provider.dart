import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_market_sdk/market/api.dart';
import 'package:am_market_ui/core/services/market_data_sdk_service.dart';
import 'package:am_auth_ui/core/services/secure_storage_service.dart';
import 'package:get_it/get_it.dart';

final fundamentalProfileProvider =
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
    return await sdkService.fundamentalApi.getProfile(symbol);
  } catch (e) {
    throw Exception('Failed to load profile for $symbol: $e');
  }
});

final fundamentalRatiosProvider =
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
    return await sdkService.fundamentalApi.getRatios(symbol);
  } catch (e) {
    throw Exception('Failed to load ratios for $symbol: $e');
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
    FutureProvider.family<List<CompetitorPeer>?, String>((ref, symbol) async {
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
    final peers = await sdkService.fundamentalApi.getPeers(symbol);

    if (peers != null && peers.isNotEmpty) {
      final symbolsToFetch = <String>{};
      symbolsToFetch.add(symbol); // main symbol
      for (final p in peers) {
        if (p.symbol != null) symbolsToFetch.add(p.symbol!);
      }

      if (symbolsToFetch.isNotEmpty) {
        try {
          final quotesRes = await sdkService.marketDataApi.getQuotes(symbolsToFetch.join(','));
          if (quotesRes != null && quotesRes.containsKey('quotes')) {
            final quotes = quotesRes['quotes'] as Map;

            for (final p in peers) {
              final sym = p.symbol?.toUpperCase();
              if (sym != null && quotes.containsKey(sym)) {
                final quote = quotes[sym] as Map;
                if (quote['lastPrice'] != null) {
                  final lastP = (quote['lastPrice'] as num).toDouble();
                  if (lastP > 0) {
                    p.currentPrice = lastP;
                  }
                }
                if (quote['previousClose'] != null && quote['lastPrice'] != null) {
                  final prev = (quote['previousClose'] as num).toDouble();
                  final last = (quote['lastPrice'] as num).toDouble();
                  if (prev > 0 && last > 0) {
                    p.dayChangePercent = ((last - prev) / prev) * 100;
                  }
                }
              }
            }
          }
        } catch (e) {
          print('Failed to merge live quotes: $e');
        }
      }
    }
    return peers;
  } catch (e) {
    throw Exception('Failed to load peers for $symbol: $e');
  }
});
