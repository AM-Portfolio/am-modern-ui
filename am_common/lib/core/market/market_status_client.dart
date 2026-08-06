import 'package:am_library/am_library.dart';

import '../config/env_domains.dart';
import 'market_status.dart';

typedef MarketStatusFetcher = Future<MarketStatus> Function({String exchange});

/// Fetches live market status from am-market-data (JWT required).
class MarketStatusClient {
  MarketStatusClient({ApiClient? apiClient, MarketStatusFetcher? fetchOverride})
      : _apiClient = apiClient ?? ApiClient(baseUrl: EnvDomains.market),
        _fetchOverride = fetchOverride;

  final ApiClient _apiClient;
  final MarketStatusFetcher? _fetchOverride;

  /// Exchange locked to NSE for v1 (matches market-data scheduler default).
  Future<MarketStatus> fetchStatus({String exchange = 'NSE'}) {
    final override = _fetchOverride;
    if (override != null) return override(exchange: exchange);
    return _apiClient.get(
      '/v1/market-calendar/status',
      queryParams: {'exchange': exchange},
      parser: (data) => MarketStatus.fromJson(data as Map<String, dynamic>),
    );
  }
}
