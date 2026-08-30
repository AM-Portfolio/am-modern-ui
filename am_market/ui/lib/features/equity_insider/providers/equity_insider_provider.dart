import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_market_client/api.dart';
import 'package:am_market_ui/core/services/market_data_sdk_service.dart';

/// Provider for fetching Fundamental Ratios from the backend API.
final fundamentalAnalysisProvider = FutureProvider.family<FundamentalRatiosResponse?, String>((ref, symbol) async {
  // Use MarketDataSdkService which initializes the API client globally.
  final sdkService = MarketDataSdkService();
  final fundamentalApi = sdkService.fundamentalApi;

  try {
    return await fundamentalApi.getRatios(symbol);
  } catch (e) {
    throw Exception('Failed to load fundamental data for $symbol: $e');
  }
});
