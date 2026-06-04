import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:am_common/am_common.dart' as common;
import 'package:am_auth_ui/core/services/secure_storage_service.dart';
import 'package:am_design_system/am_design_system.dart';

/// Data Transfer Object for a Market Mover Stock
class MarketMoverStock {
  final String symbol;
  final String companyName;
  final double lastPrice;
  final double change;
  final double changePercent;
  final int volume;

  MarketMoverStock({
    required this.symbol,
    required this.companyName,
    required this.lastPrice,
    required this.change,
    required this.changePercent,
    required this.volume,
  });

  factory MarketMoverStock.fromJson(Map<String, dynamic> json) {
    return MarketMoverStock(
      symbol: json['symbol'] as String? ?? '',
      companyName: json['companyName'] as String? ?? json['symbol'] as String? ?? '',
      lastPrice: (json['lastPrice'] as num?)?.toDouble() ?? 0.0,
      change: (json['change'] as num?)?.toDouble() ?? 0.0,
      changePercent: (json['changePercent'] as num?)?.toDouble() ??
          (json['pChange'] as num?)?.toDouble() ??
          0.0,
      volume: (json['volume'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Result object holding both gainers and losers
class MarketMoversData {
  final List<MarketMoverStock> gainers;
  final List<MarketMoverStock> losers;

  MarketMoversData({required this.gainers, required this.losers});
}

/// Service to fetch actual market top gainers/losers from the am-market backend
class MarketMoversService {
  final _storage = SecureStorageService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Fetches global market movers (gainers and losers)
  Future<MarketMoversData> fetchMarketMovers({
    int limit = 5,
    String indexSymbol = 'NIFTY 50',
    String timeFrame = '1D',
  }) async {
    try {
      final baseUrl = common.ConfigService.config.api.marketData?.baseUrl ??
          'https://am-dev.asrax.in/market';
          
      // Ensure we hit the unified endpoint that returns {gainers: [], losers: []}
      final uri = Uri.parse(
          '$baseUrl/v1/analysis/movers?type=all&limit=$limit&indexSymbol=$indexSymbol&timeFrame=$timeFrame');

      CommonLogger.info('Fetching global market movers from $uri',
          tag: 'MarketMoversService');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Connection timeout fetching market movers'),
      );

      if (response.statusCode == 200) {
        CommonLogger.info('Market movers response: ${response.body}',
            tag: 'MarketMoversService');
        final Map<String, dynamic> data = json.decode(response.body);

        final gainersList = (data['gainers'] as List<dynamic>?) ?? [];
        final losersList = (data['losers'] as List<dynamic>?) ?? [];

        return MarketMoversData(
          gainers: gainersList.map((e) => MarketMoverStock.fromJson(e)).toList(),
          losers: losersList.map((e) => MarketMoverStock.fromJson(e)).toList(),
        );
      } else {
        CommonLogger.error(
            'Failed to fetch market movers: ${response.statusCode} - ${response.body}',
            tag: 'MarketMoversService');
        throw Exception('Failed to fetch market movers: ${response.statusCode}');
      }
    } catch (e) {
      CommonLogger.error('Error in fetchMarketMovers',
          tag: 'MarketMoversService', error: e);
      // Return empty data on failure rather than breaking the UI
      return MarketMoversData(gainers: [], losers: []);
    }
  }
}
