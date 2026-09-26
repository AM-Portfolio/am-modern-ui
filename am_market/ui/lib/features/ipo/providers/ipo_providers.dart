import 'package:am_market_ui/core/services/market_data_sdk_service.dart';
import 'package:am_market_ui/features/ipo/data/ipo_api_client.dart';
import 'package:am_market_ui/features/ipo/models/ipo_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ipoApiClientProvider = Provider<IpoApiClient>((ref) {
  final sdkService = MarketDataSdkService();
  return IpoApiClient(sdkService);
});

final ipoCountsProvider = FutureProvider<AsraxIpoCountsDto>((ref) async {
  final client = ref.watch(ipoApiClientProvider);
  return await client.getIpoCounts();
});

final ipoListProvider = FutureProvider.family<List<AsraxIpoSummaryDto>, String>((ref, status) async {
  final client = ref.watch(ipoApiClientProvider);
  return await client.getIpos(status);
});

final ipoDetailsProvider = FutureProvider.family<AsraxIpoDetailsDto, String>((ref, id) async {
  final client = ref.watch(ipoApiClientProvider);
  return await client.getIpoDetails(id);
});
