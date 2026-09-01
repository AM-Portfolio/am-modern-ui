import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:am_market_sdk/market/api.dart';
import 'package:am_market_ui/core/services/market_data_sdk_service.dart';
import 'package:am_auth_ui/core/services/secure_storage_service.dart';
import 'package:get_it/get_it.dart';

/// Provider for fetching unified Fundamental Analysis from the backend API.
/// Calls GET /v1/fundamentals/{symbol}.
final fundamentalAnalysisProvider =
    FutureProvider.family<FundamentalRatiosResponse?, String>((ref, symbol) async {
  final sdkService = MarketDataSdkService();

  // Attach Bearer token — prod /v1/** requires auth.
  try {
    if (GetIt.I.isRegistered<SecureStorageService>()) {
      final token = await GetIt.I<SecureStorageService>().getAccessToken();
      if (token != null && token.isNotEmpty) {
        sdkService.setAuthentication(token);
      }
    }
  } catch (_) {
    // Continue without token; API will return 401 if required.
  }

  try {
    return await sdkService.fundamentalApi.getFundamentals(symbol);
  } catch (e) {
    throw Exception('Failed to load fundamental data for $symbol: $e');
  }
});
